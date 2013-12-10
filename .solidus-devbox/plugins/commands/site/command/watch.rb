require 'optparse'
require_relative 'site'

module VagrantPlugins
  module CommandSite
    module Command
      class Watch < SiteCommand
        IGNORED_SITE_DIRECTORIES = [/\.sass-cache/, /deploy/, /node_modules/]
        SITE_STATUS_POLLING_FREQUENCY = 5

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
            start_listening

            Vagrant::Util::Busy.busy(method(:stop_listening)) do
              wait_for_interrupt
            end
          end

          # Success, exit status 0
          0
        end

        protected

        def start_listening
          @listener = Listen.to(@site_host_path, ignore: IGNORED_SITE_DIRECTORIES, &method(:send_file_events_to_vm))
          @listener.start
          @listening = true
        end

        def send_file_events_to_vm(modified, added, removed)
          (modified + added).each do |file_host_path|
            @env.ui.info(file_host_path) unless @silent
            file_guest_path = File.join(@site_guest_path, file_host_path.gsub(@site_host_path, ''))
            guest_exec(nil, "cat #{file_guest_path} > /dev/null")
          end
        end

        def stop_listening
          @listener.stop
          @listening = false
        end

        def wait_for_interrupt
          i = 0
          begin
            validate_site_status if i % SITE_STATUS_POLLING_FREQUENCY == 0
            sleep 1 if @listening
          end while @listening && i += 1
        end

        def validate_site_status
          started = site_started? rescue false
          unless started
            @env.ui.error("#{@site_name} is stopped") unless @silent
            stop_listening
          end
        end
      end
    end
  end
end
