require 'optparse'
require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Watch < SiteCommand
        IGNORED_SITE_DIRECTORIES = [/\.sass-cache/, /deploy/, /node_modules/]

        def description(opts)
          opts.separator "Watch the site's files (the default VirtualBox watcher is not reliable)."
        end

        def options(opts)
          opts.on("-s", "--silent", "Silent mode. Don't output anything.") do |url|
            @silent = true
          end
        end

        def execute
          super do
            @env.ui.info("Watching #{@site_name} (press Ctrl+C to quit)...") unless @silent

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
            @env.ui.info(file_host_path) unless @silent
            file_guest_path = File.join(@site_guest_path, file_host_path.gsub(@site_host_path, ''))
            with_mutex {guest_exec(nil, "head -c 1 #{file_guest_path} > /dev/null")}
          end
        end

        def wait_until_listener_or_site_is_stopped
          while @listener.listen?
            if with_mutex {site_started? rescue false}
              sleep(SITE_STATUS_WATCHER_POLLING_FREQUENCY)
            else
              @env.ui.error("#{@site_name} is stopped") unless @silent
              @listener.stop
            end
          end
        end
      end
    end
  end
end
