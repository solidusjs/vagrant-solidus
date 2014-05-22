require_relative '../command'

module VagrantPlugins
  module Solidus
    module Site
      class Command < VagrantPlugins::Solidus::Command
        def self.synopsis
          'manages Solidus sites'
        end

        def command
          'site'
        end

        def subcommands
          %w[create log restart run start status stop update watch]
        end
      end
    end
  end
end
