require "vagrant"
require_relative 'site_helpers'

module VagrantPlugins
  module CommandSite
    class Plugin < Vagrant.plugin("2")
      name "site command"
      description "The `site` command manages Solidus sites in the virtual machine."

      command("site") do
        require File.expand_path("../command/root", __FILE__)
        Command::Root
      end
    end
  end
end
