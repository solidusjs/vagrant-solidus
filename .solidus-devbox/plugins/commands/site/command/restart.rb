require 'optparse'
require_relative 'start'

module VagrantPlugins
  module CommandSite
    module Command
      # This is just an alias for the Start command...
      class Restart < Start
        def description(opts)
          opts.separator "Restart a running site, or start it if it is stopped."
        end
      end
    end
  end
end
