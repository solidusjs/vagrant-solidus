require_relative 'site'

module VagrantPlugins
  module Solidus
    module Site
      class Run < SiteCommand
        def parse_arguments
          extra_argv = parse_argv(1..Float::INFINITY) do |opts|
            opts.banner << " <command>"
            opts.separator "Run a command in the context of the site."
            opts.separator ""
            site_name_command_line_option(opts)
          end

          @guest_command = extra_argv.join(' ')
        end

        def execute
          with_running_vm do
            guest_exec(:log_all, "cd #{@site_guest_path} && #{@guest_command}")
          end

          # Command's exit status
          @last_exit_code
        end
      end
    end
  end
end
