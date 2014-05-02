require_relative 'site'

module VagrantPlugins
  module Solidus
    module Site
      class Log < SiteCommand
        def parse_arguments
          parse_argv do |opts|
            opts.separator "Follow the site's log file."
            opts.separator ""
            site_name_command_line_option(opts)
          end
        end

        def execute
          with_running_vm do
            @env.ui.info("Following #{@site_log_file_path} (press Ctrl+C to quit)...")
            follow_site_log
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
