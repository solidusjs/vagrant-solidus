module VagrantPlugins
  module Solidus
    class Provisioner < Vagrant.plugin('2', :provisioner)
      include VagrantPlugins::Solidus::SiteHelpers

      def configure(root_config)
        (root_config.solidus.site_ports + root_config.solidus.livereload_ports + root_config.solidus.log_server_ports).each do |port|
          root_config.vm.network :forwarded_port, guest: port, host: port
        end
      end

      def provision
        # ***********************************************************************
        # !! IMPORTANT !! Update SiteHelpers::PROVISION_ID when this method is
        #                 changed, to force a re-provisioning.
        # ***********************************************************************

        @env = @machine.env

        @env.ui.info('Retrieving new lists of packages')
        execute('apt-get update', sudo: true)

        @env.ui.info('Installing curl')
        execute('apt-get -y install curl', sudo: true)

        @env.ui.info('Installing vim')
        execute('apt-get -y install vim', sudo: true)

        @env.ui.info('Installing git')
        execute('apt-get -y install git', sudo: true)

        @env.ui.info('Installing dos2unix')
        execute('apt-get -y install dos2unix', sudo: true)

        @env.ui.info('Installing nvm')
        execute('curl -s -o- https://raw.githubusercontent.com/creationix/nvm/v0.25.1/install.sh | bash')
        unless guest_exec(nil, 'grep NVM_DIR ~/.profile')
          execute('echo \'export NVM_DIR="/home/vagrant/.nvm"\' >> ~/.profile')
          execute('echo \'[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm\' >> ~/.profile')
        end

        # Install a default node.js version, it will be used for grunt-init and when ssh'ing into the box
        @env.ui.info('Installing node.js')
        execute("nvm install #{DEFAULT_NODE_VERSION}")
        execute("nvm use #{DEFAULT_NODE_VERSION}")
        execute("nvm alias default #{DEFAULT_NODE_VERSION}")

        @env.ui.info('Installing npm')
        execute("npm install npm@'#{DEFAULT_NPM_VERSION}' -g")

        @env.ui.info('Installing grunt-init')
        execute('npm install grunt-init@"~0.3.1" -g')

        @env.ui.info('Configuring rubygems')
        @machine.communicate.upload(File.expand_path('provisioner/.gemrc', File.dirname(__FILE__)), '/home/vagrant/.gemrc')
        execute('dos2unix -o ~/.gemrc')

        @env.ui.info('Installing rvm and ruby')
        execute('gpg --keyserver hkp://keys.gnupg.net --recv-keys D39DC0E3')
        execute('curl -sSL https://get.rvm.io | bash -s stable --ruby=1.9.3-p545')
        execute('source ~/.rvm/scripts/rvm')
        execute('rvm rvmrc warning ignore allGemfiles')
        execute('rvm use --default ruby-1.9.3-p545')

        @env.ui.info('Installing bundler')
        execute('gem install bundler')

        @env.ui.info('Updating libstdc++')
        execute('apt-get -y install python-software-properties', sudo: true)
        execute('add-apt-repository -y ppa:ubuntu-toolchain-r/test', sudo: true)
        execute('apt-get update', sudo: true)
        execute('DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade', sudo: true)

        @env.ui.info('Configuring bash')
        @machine.communicate.upload(File.expand_path('provisioner/.bashrc', File.dirname(__FILE__)), '/home/vagrant/.bashrc-vagrant-solidus')
        execute('dos2unix -o ~/.bashrc-vagrant-solidus')
        unless guest_exec(nil, 'grep "^\. ~/.bashrc-vagrant-solidus" ~/.bashrc')
          execute('echo ". ~/.bashrc-vagrant-solidus" >> ~/.bashrc')
          execute('. ~/.bashrc-vagrant-solidus')
        end

        execute(provisioned!)

        # ***********************************************************************
        # !! IMPORTANT !! Update SiteHelpers::PROVISION_ID when this method is
        #                 changed, to force a re-provisioning.
        # ***********************************************************************
      end

      private

      def execute(*args)
        unless guest_exec(:log_on_error, *args)
          @env.ui.error('Virtual machine could not be provisioned')
          abort
        end
      end
    end
  end
end
