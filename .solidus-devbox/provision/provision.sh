function echoerr {
  if ! output=$("$@" 2>&1); then
    echo "$@" >&2
    echo "$output" >&2
    echo "" >&2
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
source ~/.nvm/nvm.sh
echoerr nvm install 0.10.22
nvm use 0.10.22 > /dev/null # Using echoerr here doesn't work, mystery...
echoerr nvm alias default 0.10.22

echo "Installing grunt.js"
echoerr npm install -g grunt-cli
echoerr npm install -g grunt-init@">=0.3.0" # We need 0.3.0 for the --default option

echo "Installing rvm and ruby"
curl -s -L https://get.rvm.io | echoerr bash
source ~/.rvm/scripts/rvm
echoerr rvm install ruby-1.9.3-p484
echoerr rvm rvmrc warning ignore allGemfiles
rvm use --default ruby-1.9.3-p484 > /dev/null # Using echoerr here doesn't work, mystery...

echo "Installing sass"
echoerr gem install sass

echo "Installing dos2unix"
echoerr sudo apt-get install -y dos2unix

echo "Setuping bash"
bashrc_solidus_devbox=${HOME}/.bashrc_solidus_devbox
echoerr cp /vagrant/.solidus-devbox/provision/.bashrc $bashrc_solidus_devbox
echoerr dos2unix $bashrc_solidus_devbox
if ! grep "^\. $bashrc_solidus_devbox" ~/.bashrc &> /dev/null; then
  echo ". $bashrc_solidus_devbox" >> ~/.bashrc
  . $bashrc_solidus_devbox
fi
