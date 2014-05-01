module VagrantPlugins
  module CommandSite
    module SiteHelpers
      BASE_PORT = 8081
      BASE_LIVERELOAD_PORT = 35730
      SITE_TEMPLATE_GIT_URL = "https://github.com/solidusjs/solidus-site-template.git"
      SITE_STATUS_WATCHER_POLLING_FREQUENCY = 1

      #########################################################################
      # System Calls
      #########################################################################

      def host_exec(log_type, *args)
        with_log(log_type) do
          @last_exit_code = Vagrant::Util::Subprocess.execute(*args, {notify: [:stdout, :stderr]}, &method(:log_callback)).exit_code
          @last_exit_code == 0
        end
      end

      def guest_exec(log_type, command, opts = {})
        with_log(log_type) do
          @last_exit_code = @machine.communicate.execute(command, {error_check: false}.merge(opts), &method(:log_callback))
          @last_exit_code == 0
        end
      end

      def with_log(log_type)
        @log_type   = log_type
        @log_buffer = []
        success = yield
        @log_buffer.each {|args| log(*args)} if @log_type == :log_on_error && !success
        return success
      ensure
        @log_type   = nil
        @log_buffer = nil
      end

      def log_callback(*args)
        case @log_type
        when :log_all
          log(*args)
        when :log_on_error
          @log_buffer << args
        end
      end

      def log(type, data)
        @env.ui.info(data, prefix: false, new_line: false, channel: type == :stdout ? :out : :error)
      end

      def with_mutex
        @mutex ||= Mutex.new
        @mutex.synchronize do
          yield
        end
      end

      #########################################################################
      # Sites Management
      #########################################################################

      def sites
        @@sites ||= File.exists?(SITES_CONFIGS_FILE_HOST_PATH) ? JSON.load(File.new(SITES_CONFIGS_FILE_HOST_PATH)) : {}
      end

      def load_site(site_name)
        @site_name                = site_name.chomp('/')
        @site_host_path           = File.join(ROOT_HOST_PATH, @site_name)
        @site_guest_path          = File.join(ROOT_GUEST_PATH, @site_name)
        @site_log_file_path       = ".solidus-devbox/log/#{@site_name}.log"
        @site_log_file_guest_path = File.join(ROOT_GUEST_PATH, @site_log_file_path)

        if config = sites[@site_name]
          @site_port            = config['port']
          @site_livereload_port = config['livereload-port']
        end

        @site_port            ||= find_next_available_port('port', BASE_PORT)
        @site_livereload_port ||= find_next_available_port('livereload-port', BASE_LIVERELOAD_PORT)
      end

      def find_next_available_port(type, port)
        ports = sites.values.map {|config| config[type]}
        loop do
          return port unless ports.index(port)
          port += 1
        end
      end

      def validate_site
        gruntfile = File.join(@site_host_path, 'Gruntfile.js')
        package   = File.join(@site_host_path, 'package.json')
        File.exists?(gruntfile) && File.exists?(package) && File.read(package).index('solidus')
      end

      def save_site
        config = {'port' => @site_port, 'livereload-port' => @site_livereload_port}
        File.open(SITES_CONFIGS_FILE_HOST_PATH, 'w') do |file|
          file.write(JSON.pretty_generate(sites.merge(@site_name => config)))
        end
      end

      #########################################################################
      # Site Log
      #########################################################################

      def follow_site_log
        command = "tail -f -n 0 #{@site_log_file_guest_path}"
        begin
          guest_exec(:log_all, command)
        rescue Interrupt
          # Don't forget to stop tail in the vm
          guest_exec(nil, "kill -s SIGINT `pgrep -f \"#{command}\"`")
        end
      end

      def log_site_log_tail(lines)
        guest_exec(:log_all, "tail -n #{lines} #{@site_log_file_guest_path}")
      end

      #########################################################################
      # Site dependencies
      #########################################################################

      def install_site_dependencies
        # Ruby gems
        if File.exists?(File.join(@site_host_path, 'Gemfile'))
          return unless guest_exec(:log_on_error, "cd #{@site_guest_path} && bundle install")
        else
          return unless guest_exec(:log_on_error, "gem install sass")
        end

        # Node packages
        return unless guest_exec(:log_on_error, "npm install bower -g")

        return true
      end

      #########################################################################
      # Node.js
      #########################################################################

      def install_site_node_packages
        return unless create_guest_node_modules_symlink
        guest_exec(:log_on_error, "cd #{@site_guest_path} && npm install")
      end

      def create_guest_node_modules_symlink
        # Create link target
        target = "~/.solidus-devbox/node_modules/#{@site_name}"
        return unless guest_exec(:log_on_error, "mkdir -p #{target}")

        # Make sure link doesn't exist
        link = File.join(@site_guest_path, 'node_modules')
        return unless guest_exec(:log_on_error, "if [ -e #{link} ] ; then rm -r #{link} ; fi")

        guest_exec(:log_on_error, "ln -s #{target} #{link}")
      end

      #########################################################################
      # Upstart
      #########################################################################

      def install_site_service
        conf = "exec su - vagrant -c 'cd #{@site_guest_path} && grunt dev -port #{@site_port} -livereloadport #{@site_livereload_port} >> #{@site_log_file_guest_path} 2>&1'"
        guest_exec(:log_on_error, "echo \"#{conf}\" > /etc/init/#{site_service_name}.conf", sudo: true)
      end

      def uninstall_site_service
        guest_exec(nil, "rm /etc/init/#{site_service_name}.conf", sudo: true)
      end

      def start_site_service
        guest_exec(:log_on_error, "start #{site_service_name}", sudo: true)
      end

      def stop_site_service
        guest_exec(nil, "stop #{site_service_name}", sudo: true)
      end

      def stop_site
        stop_site_service
        wait_for_site_watcher_to_stop
      end

      def site_started?
        guest_exec(nil, "status #{site_service_name} | grep 'start/running'", sudo: true)
      end

      def site_responding?
        loop do
          return false unless site_started?
          return true if guest_exec(nil, "curl --head localhost:#{@site_port}/status")
          sleep 0.5
        end
      end

      def site_service_name
        "site-#{@site_name}"
      end

      #########################################################################
      # Pow
      #########################################################################

      def pow_installed?
        File.directory?(File.expand_path("~/.pow"))
      end

      def install_pow_site
        File.write(File.expand_path("~/.pow/#{@site_name}"), @site_port)
      end

      def uninstall_pow_site
        File.delete(File.expand_path("~/.pow/#{@site_name}")) if File.exists?(File.expand_path("~/.pow/#{@site_name}"))
      end

      #########################################################################
      # Site Watcher
      #########################################################################

      def start_site_watcher
        command = "vagrant site watch #{@site_name} -s"
        Process.detach(Process.spawn(command, chdir: ROOT_HOST_PATH))
      end

      def wait_for_site_watcher_to_stop
        sleep(SITE_STATUS_WATCHER_POLLING_FREQUENCY)
      end

      #########################################################################
      # Site Template
      #########################################################################

      def clone_site_template(site_template_git_url)
        site_template_git_url ||= SITE_TEMPLATE_GIT_URL
        FileUtils.rm_rf(SITE_TEMPLATE_HOST_PATH)
        fail("Site template could not be cloned") unless host_exec(:log_on_error, "git", "clone", site_template_git_url, SITE_TEMPLATE_HOST_PATH)
        wait_until_guest_directory_exists(SITE_TEMPLATE_GUEST_PATH)
      end

      def create_site_from_template(site_template_guest_path)
        site_template_guest_path ||= SITE_TEMPLATE_GUEST_PATH
        fail("Site could not be created") unless guest_exec(:log_on_error, "mkdir -p #{@site_guest_path}")
        fail("Site could not be created") unless create_guest_node_modules_symlink
        fail("Site could not be created") unless guest_exec(:log_on_error, "cd #{@site_guest_path} && grunt-init --default=1 --force #{site_template_guest_path}")
      end

      def site_template_command_line_options(opts)
        opts.on("-g", "--template-git-url [URL]", "URL of the Solidus site template Git repository", "Default: #{SITE_TEMPLATE_GIT_URL}") do |url|
          @site_template_git_url = url
        end
        opts.on("-p", "--template-path [PATH]", "Path of the Solidus site template to use, instead of the Git repository", "Must be relative to the Vagrantfile's directory") do |path|
          @site_template_host_path  = File.join(ROOT_HOST_PATH, path)
          @site_template_guest_path = File.join(ROOT_GUEST_PATH, path)
        end
      end

      #########################################################################
      # Misc
      #########################################################################

      def fail(error)
        @env.ui.error(error)
        abort
      end

      def wait_until_guest_directory_exists(directory)
        until guest_exec(nil, "cd #{directory}") do
          sleep 0.5
        end
      end

      def directory_exists?(directory)
        File.directory?(directory) && !(Dir.entries(directory) - %w{. ..}).empty?
      end

      def log_site_urls
        @env.ui.info("  Local URL:")
        @env.ui.info("    http://#{@site_name}.dev") if pow_installed?
        @env.ui.info("    http://lvh.me:#{@site_port}")
        @env.ui.info("    http://localhost:#{@site_port}")
        @env.ui.info("  Network URL:")
        @env.ui.info("    http://#{@site_name}.#{ip_address}.xip.io") if pow_installed?
        @env.ui.info("    http://#{ip_address}.xip.io:#{@site_port}")
      end

      def ip_address
        @ip_address ||= Socket.ip_address_list.detect(&:ipv4_private?).ip_address
      end
    end
  end
end
