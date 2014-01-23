require 'optparse'
require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Log < SiteCommand
        def description(opts)
          opts.separator "Follow the site's log file."
        end

        def execute
          super do
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
