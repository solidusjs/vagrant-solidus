require 'optparse'
require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Status < SiteCommand
        def execute
          super do
            Dir[File.join(ROOT_HOST_PATH, '*')].each do |path|
              @site_name = File.basename(path)
              load_site
              next unless validate_site

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

        protected

        def parse_arguments
          opts = OptionParser.new do |opts|
            opts.banner = "Usage: vagrant site status"
            opts.separator ""
            opts.separator "Show the current status of all available sites."
            opts.separator ""
          end

          abort unless argv = parse_options(opts)
        end
      end
    end
  end
end
