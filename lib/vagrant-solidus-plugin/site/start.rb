require_relative 'site'

module VagrantPlugins
  module Solidus
    module Site
      class Start < SiteCommand
        def parse_arguments
          parse_argv do |opts|
            opts.separator "Install and start the site."
            opts.separator ""
            site_start_command_line_options(opts)
          end
        end

        def execute
          with_running_vm do
            stop_site

            unless @fast
              @env.ui.info("Installing site...")
              fail("Site could not be installed") unless install_site
              install_pow_site if pow_installed?
            end

            @env.ui.info("Starting dev server...")
            fail("Site could not be started") unless start_site_service

            if site_responding?
              save_site
              start_site_watcher unless @deaf

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

        private

        def install_site
          install_site_dependencies && install_site_node_packages && install_site_service
        end
      end
    end
  end
end
