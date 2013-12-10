require 'optparse'
require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Start < SiteCommand
        def description(opts)
          opts.separator "Install and start the site. The site will be automatically restarted if the vm is restarted."
        end

        def execute
          super do
            @env.ui.info("Installing site...")
            stop_site_service
            fail("Site could not be installed") unless install_site_node_packages
            fail("Site could not be installed") unless install_site_service
            install_pow_site if pow_installed?

            @env.ui.info("Starting dev server...")
            fail("Site could not be started") unless start_site_service

            if site_responding?
              save_site
              start_site_watcher

              @env.ui.success("#{@site_name} is started, accessible here:")
              log_site_urls
            else
              log_site_log_tail(10)
              fail("Site could not be started")
            end
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
