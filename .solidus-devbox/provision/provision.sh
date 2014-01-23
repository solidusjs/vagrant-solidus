function header {
  echo ""
  echo "********************************************************************************"
  echo "$(date +"%m-%d-%Y %T") - $1"
  echo "********************************************************************************"
}

sudo apt-get update

header "Installing curl"
sudo apt-get install -y curl

header "Installing vim"
sudo apt-get -y install vim

header "Installing git"
sudo apt-get install -y git

header "Installing nvm, node.js and npm"
curl https://raw.github.com/creationix/nvm/master/install.sh | sh
source ~/.profile
nvm install 0.10.22
nvm use 0.10.22
nvm alias default 0.10.22

header "Installing grunt.js"
npm install -g grunt-cli
npm install -g git+https://github.com/gruntjs/grunt-init#54ca267f45 # Need edge code, for the --default option

header "Installing rvm and ruby"
curl -L https://get.rvm.io | bash
source ~/.rvm/scripts/rvm
rvm install ruby-1.9.3-p484
rvm rvmrc warning ignore allGemfiles
rvm use 1.9.3-p484 --default

header "Installing sass"
gem install sass

header "Setuping bash"
if ! grep "^\. /vagrant/.solidus-devbox/provision/\.bashrc" ~/.bashrc &> /dev/null; then
  echo . /vagrant/.solidus-devbox/provision/.bashrc >> ~/.bashrc
  . /vagrant/.solidus-devbox/provision/.bashrc
fi
