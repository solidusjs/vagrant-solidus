require 'optparse'
require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Run < SiteCommand
        def execute
          super do
            guest_exec(:log_all, @guest_command)
          end

          @last_exit_code
        end

        protected

        def parse_arguments
          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant site run <site> <command>"
            opts.separator ""
            opts.separator "Run a command in the context of the site."
            opts.separator ""
          end

          begin
            # Parse for the -h option
            abort unless parse_options(opts)
          rescue Vagrant::Errors::CLIInvalidOptions
            # Ignore invalid options from the site command
          end
          raise Vagrant::Errors::CLIInvalidUsage, help: opts.help.chomp if ARGV.size < 4

          load_and_validate_site!(ARGV[2])

          @guest_command = "cd #{@site_guest_path} && #{ARGV[3..-1].join(' ')}"
        end
      end
    end
  end
end
