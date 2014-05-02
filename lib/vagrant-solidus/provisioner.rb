module VagrantPlugins
  module Solidus
    class Provisioner < Vagrant.plugin('2', :provisioner)
      include VagrantPlugins::Solidus::SiteHelpers

      def configure(root_config)
        # TODO: Make this configurable
        15.times do |i|
          port = VagrantPlugins::Solidus::SiteHelpers::BASE_PORT + i
          root_config.vm.network :forwarded_port, guest: port, host: port

          port = VagrantPlugins::Solidus::SiteHelpers::BASE_LIVERELOAD_PORT + i
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

        @env.ui.info('Installing nvm, node.js and npm')
        execute('curl -s https://raw.githubusercontent.com/creationix/nvm/v0.5.1/install.sh | sh')
        execute('source ~/.nvm/nvm.sh')
        execute('nvm install 0.10.22')
        execute('nvm use 0.10.22')
        execute('nvm alias default 0.10.22')

        @env.ui.info('Installing grunt.js')
        execute('npm install grunt-cli@"~0.1.13" -g')
        execute('npm install grunt-init@"~0.3.1" -g')

        @env.ui.info('Configuring rubygems')
        @machine.communicate.upload(File.expand_path('provisioner/.gemrc', File.dirname(__FILE__)), '/home/vagrant/.gemrc')
        execute('dos2unix -o ~/.gemrc')

        @env.ui.info('Installing rvm and ruby')
        execute('curl -sSL https://get.rvm.io | bash -s stable --ruby=1.9.3-p545')
        execute('source ~/.rvm/scripts/rvm')
        execute('rvm rvmrc warning ignore allGemfiles')
        execute('rvm use --default ruby-1.9.3-p545')

        @env.ui.info('Configuring bash')
        @machine.communicate.upload(File.expand_path('provisioner/.bashrc', File.dirname(__FILE__)), '/home/vagrant/.bashrc_solidus_devbox')
        execute('dos2unix -o ~/.bashrc_solidus_devbox')
        unless guest_exec(nil, 'grep "^\. ~/.bashrc_solidus_devbox" ~/.bashrc')
          execute('echo ". ~/.bashrc_solidus_devbox" >> ~/.bashrc')
          execute('. ~/.bashrc_solidus_devbox')
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
