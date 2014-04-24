require_relative 'start'

module VagrantPlugins
  module CommandSite
    module Command
      # This is just an alias for the Start command...
      class Restart < Start
        def parse_arguments
          parse_argv do |opts|
            opts.separator "Restart a running site, or start it if it is stopped."
            opts.separator ""
            site_start_command_line_options(opts)
          end
        end
      end
    end
  end
end
