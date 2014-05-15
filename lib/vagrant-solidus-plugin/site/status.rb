require_relative 'site'

module VagrantPlugins
  module Solidus
    module Site
      class Status < SiteCommand
        def parse_arguments
          parse_argv do |opts|
            opts.separator "Show the current status of all available sites."
            opts.separator ""
          end
        end

        def execute
          with_running_vm do
            Dir[File.join(ROOT_HOST_PATH, '*')].each do |path|
              @site_name = File.basename(path)
              next unless load_and_validate_site

              if site_started?
                @env.ui.success("#{@site_name} is started, accessible here:")
                log_site_urls
              else
                @env.ui.error("#{@site_name} is stopped")
              end
            end
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
