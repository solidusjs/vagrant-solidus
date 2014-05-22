require_relative '../command'

module VagrantPlugins
  module Solidus
    module SolidusBox
      class Command < VagrantPlugins::Solidus::Command
        def self.synopsis
          'manages Solidus box'
        end

        def command
          'solidus-box'
        end

        def subcommands
          %w[init]
        end
      end
    end
  end
end
