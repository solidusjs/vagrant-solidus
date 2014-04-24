require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Stop < SiteCommand
        def parse_arguments
          parse_argv do |opts|
            opts.separator "Stop the site."
            opts.separator ""
            site_name_command_line_option(opts)
          end
        end

        def execute
          with_running_vm do
            @env.ui.info("Stopping site...")
            stop_site
            uninstall_site_service
            uninstall_pow_site if pow_installed?

            @env.ui.success("#{@site_name} is stopped")
          end

          # Success, exit status 0
          0
        end
      end
    end
  end
end
