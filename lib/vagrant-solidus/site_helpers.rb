module VagrantPlugins
  module Solidus
    module SiteHelpers
      BASE_PORT = 8081
      BASE_UTILS_PORT = 35730
      SITE_TEMPLATE_GIT_URL = "https://github.com/solidusjs/solidus-site-template.git"
      SITE_TEMPLATE_GIT_TAG = "v1.0.0"
      SITE_STATUS_WATCHER_POLLING_FREQUENCY = 1
      PROVISION_ID = 20140502
      DEFAULT_NODE_VERSION = 'stable'
      DEFAULT_NPM_VERSION = '^2.0.0'

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

      def load_site
        @site_host_path           = File.join(ROOT_HOST_PATH, @site_name)
        @site_guest_path          = File.join(ROOT_GUEST_PATH, @site_name)
        @site_log_file_path       = ".vagrant-solidus/log/#{@site_name}.log"
        @site_log_file_guest_path = File.join(ROOT_GUEST_PATH, @site_log_file_path)
        @package                  = JSON.load(File.new(File.join(@site_host_path, 'package.json'))) rescue {}

        if config = sites[@site_name]
          @site_port            = config['port']
          @site_livereload_port = config['livereload-port']
          @site_log_server_port = config['log-server-port']
        end
      end

      def set_site_ports
        all  = @machine.config.solidus
        used = sites.values
        return unless @site_port            = find_port(@site_port,            all.site_ports,       used.map {|c| c['port']})
        return unless @site_livereload_port = find_port(@site_livereload_port, all.livereload_ports, used.map {|c| c['livereload-port']})
        return unless @site_log_server_port = find_port(@site_log_server_port, all.log_server_ports, used.map {|c| c['log-server-port']})
        return true
      end

      def find_port(current_port, all_ports, used_ports)
        all_ports.include?(current_port) ? current_port : (all_ports - used_ports).first
      end

      def validate_site
        !@package['dependencies']['solidus'].empty? rescue false
      end

      def save_site
        config = {'port' => @site_port, 'livereload-port' => @site_livereload_port, 'log-server-port' => @site_log_server_port}
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
          # Until all sites use bundler...
          return unless guest_exec(:log_on_error, "gem install sass")
        end

        # Bower packages
        if File.exists?(File.join(@site_host_path, 'bower.json'))
          return unless guest_exec(:log_on_error, "#{node_command} npm install bower -g")
          return unless guest_exec(:log_on_error, "cd #{@site_guest_path} && #{node_command} bower install")
        end

        return true
      end

      #########################################################################
      # Node.js
      #########################################################################

      def install_site_node
        guest_exec(:log_on_error, "nvm install #{node_version} && #{node_command} npm install npm@'#{npm_version}' -g")
      end

      def install_site_node_packages
        guest_exec(:log_on_error, "cd #{@site_guest_path} && #{node_command} npm install")
      end

      def node_version
        unless @node_version
          @node_version = @package['engines']['node'] if @package['engines']
          @node_version = DEFAULT_NODE_VERSION if !@node_version || @node_version.empty?
        end
        @node_version
      end

      def node_command
        "nvm exec #{node_version}"
      end

      def npm_version
        unless @npm_version
          @npm_version = @package['engines']['npm'] if @package['engines']
          @npm_version = DEFAULT_NPM_VERSION if !@npm_version || @npm_version.empty?
        end
        @npm_version
      end

      #########################################################################
      # Upstart
      #########################################################################

      def install_site_service
        command = "exec su - vagrant -c 'cd #{@site_guest_path} &&"
        logging = ">> #{@site_log_file_guest_path} 2>&1'"

        conf = ""
        return unless guest_exec(:log_on_error, "echo \"#{conf}\" > /etc/init/#{site_service_name}.conf", sudo: true)

        conf = "start on starting #{site_service_name}
                stop on stopping #{site_service_name}
                #{command} #{node_command} npm #{site_commands_arguments} run watch #{logging}"
        return unless guest_exec(:log_on_error, "echo \"#{conf}\" > /etc/init/#{site_watcher_service_name}.conf", sudo: true)

        conf = "start on starting #{site_service_name}
                stop on stopping #{site_service_name}
                #{command} #{node_command} ./node_modules/.bin/solidus start --dev --loglevel=3 #{site_commands_arguments} #{logging}"
        return unless guest_exec(:log_on_error, "echo \"#{conf}\" > /etc/init/#{solidus_server_service_name}.conf", sudo: true)

        return true
      end

      def uninstall_site_service
        guest_exec(nil, "rm /etc/init/#{site_service_name}.conf", sudo: true)
        guest_exec(nil, "rm /etc/init/#{site_watcher_service_name}.conf", sudo: true)
        guest_exec(nil, "rm /etc/init/#{solidus_server_service_name}.conf", sudo: true)
      end

      def build_site
        guest_exec(:log_on_error, "cd #{@site_guest_path} && #{node_command} npm #{site_commands_arguments} run build")
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

      def site_watcher_service_name
        "#{site_service_name}-assets-watcher"
      end

      def solidus_server_service_name
        "#{site_service_name}-server"
      end

      def site_commands_arguments
        "--port=#{@site_port} --livereloadport=#{@site_livereload_port} --logserverport=#{@site_log_server_port}"
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
        command = "vagrant site watch -s #{@site_name} -q"
        Process.detach(Process.spawn(command, chdir: ROOT_HOST_PATH))
      end

      def wait_for_site_watcher_to_stop
        sleep(SITE_STATUS_WATCHER_POLLING_FREQUENCY)
      end

      #########################################################################
      # Site Template
      #########################################################################

      def clone_site_template(site_template_git_url)
        FileUtils.rm_rf(SITE_TEMPLATE_HOST_PATH)
        if site_template_git_url
          fail("Site template could not be cloned") unless host_exec(:log_on_error, "git", "clone", site_template_git_url, SITE_TEMPLATE_HOST_PATH)
        else
          fail("Site template could not be cloned") unless host_exec(:log_on_error, "git", "clone", "--branch", SITE_TEMPLATE_GIT_TAG, SITE_TEMPLATE_GIT_URL, SITE_TEMPLATE_HOST_PATH)
        end
        wait_until_guest_directory_exists(SITE_TEMPLATE_GUEST_PATH)
      end

      def create_site_from_template(site_template_guest_path)
        site_template_guest_path ||= SITE_TEMPLATE_GUEST_PATH
        fail("Site could not be created") unless guest_exec(:log_on_error, "mkdir -p #{@site_guest_path}")
        fail("Site could not be created") unless guest_exec(:log_on_error, "cd #{@site_guest_path} && grunt-init --default=1 #{site_template_guest_path}")
      end

      #########################################################################
      # Command Line Options
      #########################################################################

      def site_name_command_line_option(opts)
        @site_name = Pathname.pwd.relative_path_from(ROOT_HOST_PATH).to_s.split(File::SEPARATOR).first

        opts.on("-s", "--site <site>", "Site to use, instead of the current directory.") do |site_name|
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if !site_name || site_name.empty?
          @site_name = site_name.chomp('/')
        end
      end

      def help_command_line_option(opts)
        opts.on("-h", "--help", "Print this help") do
          safe_puts(opts.help)
          abort
        end
      end

      def site_start_command_line_options(opts)
        site_name_command_line_option(opts)
        opts.on("-f", "--fast", "Fast mode. Don't install the site dependencies first.") do
          @fast = true
        end
        opts.on("-d", "--deaf", "Don't automatically launch the `watch` command in background (file events will be much slower).") do
          @deaf = true
        end
      end

      def quiet_command_line_option(opts)
        opts.on("-q", "--quiet", "Quiet mode. Don't output anything.") do
          @quiet = true
        end
      end

      def site_template_command_line_options(opts)
        opts.on("-g", "--template-git-url <URL>", "URL of the Solidus site template Git repository", "Default: #{SITE_TEMPLATE_GIT_URL}, #{SITE_TEMPLATE_GIT_TAG} tag") do |url|
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if !url || url.empty?
          @site_template_git_url = url
        end

        opts.on("-p", "--template-path <path>", "Path of the Solidus site template to use, instead of the Git repository", "Must be relative to the Vagrantfile's directory") do |path|
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if !path || path.empty?
          @site_template_host_path  = File.join(ROOT_HOST_PATH, path)
          @site_template_guest_path = File.join(ROOT_GUEST_PATH, path)
        end
      end

      #########################################################################
      # Provision
      #########################################################################

      def provisioned?
        guest_exec(nil, "echo #{PROVISION_ID} | diff - ~/.vagrant-solidus/provision")
      end

      def provisioned!
        "mkdir -p ~/.vagrant-solidus && echo #{PROVISION_ID} > ~/.vagrant-solidus/provision"
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
