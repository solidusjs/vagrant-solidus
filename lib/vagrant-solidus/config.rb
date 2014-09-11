module VagrantPlugins
  module Solidus
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :site_ports, :livereload_ports, :log_server_ports

      def initialize
        @site_ports       = (8081..8095).to_a
        @livereload_ports = (35730..35744).to_a
        @log_server_ports = (35745..35759).to_a
      end
    end
  end
end
