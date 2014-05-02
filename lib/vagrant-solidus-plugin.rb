require_relative 'vagrant-solidus-plugin/site_helpers'
require_relative 'vagrant-solidus-plugin/version'

module VagrantPlugins
  module Solidus
    class Plugin < Vagrant.plugin('2')
      name 'Solidus'
      description 'This plugin provides a provisioner and a `site` command that allows Solidus sites to be managed by Vagrant.'

      provisioner(:solidus) do
        require_relative 'vagrant-solidus-plugin/provisioner'
        Provisioner
      end

      command(:site) do
        require_relative 'vagrant-solidus-plugin/command'
        Command
      end
    end
  end
end
