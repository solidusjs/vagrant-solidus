module VagrantPlugins
  module Solidus
    module SolidusBox
      class Init < Vagrant.plugin('2', :command)
        def execute
          parse_arguments

          source_path = File.join(File.dirname(__FILE__), 'Vagrantfile')
          target_path = File.join(@env.root_path || Dir.pwd, 'Vagrantfile')

          abort if File.exists?(target_path) && @env.ui.ask("Are you sure you want to replace `#{target_path}`? [y/n] ") != 'y'
          FileUtils.copy(source_path, target_path)

          @env.ui.success("A `Vagrantfile` prepared for Solidus has been placed here:
                          #{target_path}
                          Run `vagrant site` to see all the available commands to manage your Solidus sites.".gsub(/^\s*/, ''))

          # Success, exit status 0
          0
        end

        protected

        def parse_arguments
          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant solidus-site init"
            opts.separator ""
            opts.separator "Create a `Vagrantfile` prepared for Solidus."
            opts.separator ""
          end

          abort unless argv = parse_options(opts)
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp unless argv.size == 0
        end
      end
    end
  end
end
