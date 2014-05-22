module VagrantPlugins
  module Solidus
    module Site
      class Subcommand < Vagrant.plugin('2', :command)
        include VagrantPlugins::Solidus::SiteHelpers

        protected

        def with_running_vm
          unless @env.root_path
            fail("A Vagrant environment is required to run this command. You can:
                  - Run `vagrant solidus-box init` to create a Solidus Vagrantfile in this directory
                  - Run `vagrant init` to create a default Vagrantfile in this directory
                  - Change to a directory with a Vagrantfile".gsub(/^\s*/, ''))
          end

          initialize_env_constants
          parse_arguments
          prepare_data_folders

          found = false
          with_target_vms do |machine|
            next unless machine.state.id == :running
            @machine = machine
            fail("Virtual machine needs to be provisioned, run `vagrant provision` and try again") unless provisioned?
            found = true
            yield
          end

          fail("Virtual machine is not started, run `vagrant up` and try again") unless found
        end

        def initialize_env_constants
          env = @env
          env_constants_module = Module.new do
            const_set :ROOT_HOST_PATH, env.root_path
            const_set :ROOT_GUEST_PATH, '/vagrant'
            const_set :DATA_HOST_PATH, File.join(self::ROOT_HOST_PATH, '.vagrant-solidus-plugin/data')
            const_set :DATA_GUEST_PATH, File.join(self::ROOT_GUEST_PATH, '.vagrant-solidus-plugin/data')
            const_set :SITE_TEMPLATE_HOST_PATH, File.join(self::DATA_HOST_PATH, 'solidus-site-template')
            const_set :SITE_TEMPLATE_GUEST_PATH, File.join(self::DATA_GUEST_PATH, 'solidus-site-template')
            const_set :SITES_CONFIGS_FILE_HOST_PATH, File.join(self::DATA_HOST_PATH, 'sites.json')
            const_set :LOG_HOST_PATH, File.join(self::ROOT_HOST_PATH, '.vagrant-solidus-plugin/log')
            const_set :LOG_GUEST_PATH, File.join(self::ROOT_GUEST_PATH, '.vagrant-solidus-plugin/log')
          end

          self.class.send(:include, env_constants_module)
          VagrantPlugins::Solidus::SiteHelpers.send(:include, env_constants_module)
        end

        def prepare_data_folders
          FileUtils.mkdir_p VagrantPlugins::Solidus::SiteHelpers::DATA_HOST_PATH
          FileUtils.mkdir_p VagrantPlugins::Solidus::SiteHelpers::LOG_HOST_PATH
        end

        def parse_argv(extra_argv_range = [0])
          opts = OptionParser.new do |opts|
            command = self.class.name.split('::').last.downcase
            opts.banner = "Usage: vagrant site #{command} [OPTIONS]"
            opts.separator ""
            yield opts
            help_command_line_option(opts)
          end

          begin
            extra_argv = opts.order(ARGV[2..-1])
          rescue OptionParser::InvalidOption
            raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp
          end

          unless extra_argv_range.include?(extra_argv.size)
            raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp
          end

          fail("Not a Solidus site: #{@site_host_path}") if @site_name && !load_and_validate_site

          return extra_argv
        end

        def load_and_validate_site
          load_site
          validate_site
        end
      end
    end
  end
end
