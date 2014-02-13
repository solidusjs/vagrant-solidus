function echoerr {
  if ! output=`"$@" 2>&1`; then
    echo $@ 1>&2
    echo $output 1>&2
    echo "" 1>&2
  fi
}

echo "Retrieving new lists of packages"
echoerr sudo apt-get update

echo "Installing curl"
echoerr sudo apt-get install -y curl

echo "Installing vim"
echoerr sudo apt-get install -y vim

echo "Installing git"
echoerr sudo apt-get install -y git

echo "Installing nvm, node.js and npm"
curl -s https://raw.github.com/creationix/nvm/master/install.sh | echoerr sh
source ~/.profile
echoerr nvm install 0.10.22
echoerr nvm use 0.10.22
echoerr nvm alias default 0.10.22

echo "Installing grunt.js"
echoerr npm install -g grunt-cli
echoerr npm install -g grunt-init@">=0.3.0" # We need 0.3.0 for the --default option

echo "Installing rvm and ruby"
curl -s -L https://get.rvm.io | echoerr bash
source ~/.rvm/scripts/rvm
echoerr rvm install ruby-1.9.3-p484
echoerr rvm rvmrc warning ignore allGemfiles
echoerr rvm use 1.9.3-p484 --default

echo "Installing sass"
echoerr gem install sass

echo "Setuping bash"
if ! grep "^\. /vagrant/.solidus-devbox/provision/\.bashrc" ~/.bashrc &> /dev/null; then
  echo . /vagrant/.solidus-devbox/provision/.bashrc >> ~/.bashrc
  . /vagrant/.solidus-devbox/provision/.bashrc
fi
