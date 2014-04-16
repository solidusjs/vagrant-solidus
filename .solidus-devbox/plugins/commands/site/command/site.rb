require 'optparse'

module VagrantPlugins
  module CommandSite
    module Command
      class SiteCommand < Vagrant.plugin("2", :command)
        include VagrantPlugins::CommandSite::SiteHelpers

        def description(opts)
          opts.separator "Override me!"
        end

        def options(opts)
        end

        def invalid_site_message
          'Not a Solidus site'
        end

        def execute
          initialize_env_constants
          parse_arguments

          found = false
          with_target_vms do |machine|
            next unless machine.state.id == :running
            @machine = machine
            found    = true
            yield
          end

          fail("Virtual machine is not started, run `vagrant up` and try again") unless found
        end

        protected

        def initialize_env_constants
          env = @env
          env_constants_module = Module.new do
            const_set :ROOT_HOST_PATH, env.root_path
            const_set :ROOT_GUEST_PATH, '/vagrant'
            const_set :DATA_HOST_PATH, File.join(self::ROOT_HOST_PATH, '.solidus-devbox/data')
            const_set :DATA_GUEST_PATH, File.join(self::ROOT_GUEST_PATH, '.solidus-devbox/data')
            const_set :SITE_TEMPLATE_HOST_PATH, File.join(self::DATA_HOST_PATH, 'solidus-site-template')
            const_set :SITE_TEMPLATE_GUEST_PATH, File.join(self::DATA_GUEST_PATH, 'solidus-site-template')
            const_set :SITES_CONFIGS_FILE_HOST_PATH, File.join(self::DATA_HOST_PATH, 'sites.json')
          end

          self.class.send(:include, env_constants_module)
          VagrantPlugins::CommandSite::SiteHelpers.send(:include, env_constants_module)
        end

        def parse_arguments
          opts = OptionParser.new do |opts|
            command = self.class.name.split('::').last.downcase
            opts.banner = "Usage: vagrant site #{command} <site>"
            opts.separator ""
            description(opts)
            opts.separator ""
            options(opts)
          end

          abort unless argv = parse_options(opts)
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp unless argv.size == 1

          load_and_validate_site!(argv[0])
        end

        def load_and_validate_site!(site_name)
          fail(invalid_site_message) unless load_and_validate_site(site_name)
        end

        def load_and_validate_site(site_name)
          load_site(site_name)
          validate_site
        end
      end
    end
  end
end
