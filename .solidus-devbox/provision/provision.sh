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
curl -s https://raw.githubusercontent.com/creationix/nvm/v0.5.1/install.sh | echoerr sh
source ~/.nvm/nvm.sh
echoerr nvm install 0.10.22
nvm use 0.10.22 > /dev/null # Using echoerr here doesn't work, mystery...
echoerr nvm alias default 0.10.22

echo "Installing grunt.js"
echoerr npm install grunt-cli@"~0.1.13" -g
echoerr npm install grunt-init@"~0.3.1" -g

echo "Installing dos2unix"
echoerr sudo apt-get install -y dos2unix

echo "Setuping rubygems"
echoerr dos2unix -n /vagrant/.solidus-devbox/provision/.gemrc ~/.gemrc

echo "Installing rvm and ruby"
curl -sSL https://get.rvm.io | echoerr bash -s stable --ruby=1.9.3-p545
source ~/.rvm/scripts/rvm
echoerr rvm rvmrc warning ignore allGemfiles
rvm use --default ruby-1.9.3-p545 > /dev/null # Using echoerr here doesn't work, mystery...

echo "Setuping bash"
bashrc_solidus_devbox=${HOME}/.bashrc_solidus_devbox
echoerr cp /vagrant/.solidus-devbox/provision/.bashrc $bashrc_solidus_devbox
echoerr dos2unix $bashrc_solidus_devbox
if ! grep "^\. $bashrc_solidus_devbox" ~/.bashrc &> /dev/null; then
  echo ". $bashrc_solidus_devbox" >> ~/.bashrc
  . $bashrc_solidus_devbox
fi
