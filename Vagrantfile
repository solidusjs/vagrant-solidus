require_relative '.solidus-devbox/plugins/commands/site/plugin'

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # Virtual Box settings
  config.vm.provider "virtualbox" do |box|
    box.name = "Solidus Devbox"
    box.customize ["modifyvm", :id, "--memory", "1024"]
  end

  # Setup environment (not sudo so rvm doesn't install multi-user)
  config.vm.box = "ubuntu-precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.hostname = "vm-solidus-devbox"
  config.vm.provision "shell", path: ".solidus-devbox/provision/provision.sh", privileged: false

  # Dev happiness
  config.vm.network :private_network, ip: "192.168.33.11"
  20.times do |i|
    port = VagrantPlugins::CommandSite::SiteHelpers::BASE_PORT + i
    config.vm.network :forwarded_port, guest: port, host: port

    port = VagrantPlugins::CommandSite::SiteHelpers::BASE_LIVERELOAD_PORT + i
    config.vm.network :forwarded_port, guest: port, host: port
  end
  config.vm.synced_folder ".", "/vagrant", nfs: true
end
