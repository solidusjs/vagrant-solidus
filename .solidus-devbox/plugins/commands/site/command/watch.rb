require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Watch < SiteCommand
        IGNORED_SITE_DIRECTORIES = [/\.sass-cache/, /deploy/, /node_modules/]

        def parse_arguments
          parse_argv do |opts|
            opts.separator "Watch the site's files (the default VirtualBox watcher is not reliable)."
            opts.separator ""
            site_name_command_line_option(opts)
            quiet_command_line_option(opts)
          end
        end

        def execute
          with_running_vm do
            @env.ui.info("Watching #{@site_name} (press Ctrl+C to quit)...") unless @quiet

            @listener = Listen.to(@site_host_path, ignore: IGNORED_SITE_DIRECTORIES, &method(:send_file_events_to_vm))
            @listener.start

            Vagrant::Util::Busy.busy(-> {@listener.stop}) do
              wait_until_listener_or_site_is_stopped
            end
          end

          # Success, exit status 0
          0
        end

        protected

        def send_file_events_to_vm(modified, added, removed)
          (modified + added + removed).each do |file_host_path|
            @env.ui.info(file_host_path) unless @quiet
            file_guest_path = File.join(@site_guest_path, file_host_path.gsub(@site_host_path, ''))
            with_mutex {guest_exec(nil, "head -c 1 #{file_guest_path} > /dev/null")}
          end
        end

        def wait_until_listener_or_site_is_stopped
          while @listener.listen?
            if with_mutex {site_started? rescue false}
              sleep(SITE_STATUS_WATCHER_POLLING_FREQUENCY)
            else
              @env.ui.error("#{@site_name} is stopped") unless @quiet
              @listener.stop
            end
          end
        end
      end
    end
  end
end
