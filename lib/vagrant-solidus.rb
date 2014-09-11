require_relative 'vagrant-solidus/site_helpers'
require_relative 'vagrant-solidus/version'

module VagrantPlugins
  module Solidus
    class Plugin < Vagrant.plugin('2')
      name 'Solidus'
      description 'This plugin provides a provisioner and a `site` command that allows Solidus sites to be managed by Vagrant.'

      config(:solidus) do
        require_relative 'vagrant-solidus/config'
        Config
      end

      provisioner(:solidus) do
        require_relative 'vagrant-solidus/provisioner'
        Provisioner
      end

      command(:site) do
        require_relative 'vagrant-solidus/site/command'
        Site::Command
      end

      command('solidus-box') do
        require_relative 'vagrant-solidus/solidus-box/command'
        SolidusBox::Command
      end
    end
  end
end
