Getting Started
---------------

This repo is designed to help you easily get Solidus sites running locally for development. We accomplish this largely by running everything within a Linux virtual machine. It’s easy to get up and running, time required is primarily to download everything, starting with the following:

### [Install VirtualBox][download-virtualbox]

[VirtualBox][virtualbox] is a free cross-platform virtualization app that makes it easy to simultaneously run multiple operating systems on your machine. In our usage it is merely a [provider][vagrant-providers] for Vagrant.

### [Install Vagrant][download-vagrant]

[Vagrant][vagrant] layers provisioning, file-based configuration, and a command-line interface on top of VirtualBox. This provides disposable, consistent environments for running development servers. [Synced Folders][vagrant-folders] and [Networking][vagrant-networking] features make the development experience the same as if running in your own environment: your own tools and whatever ports you’d like for access via your browser and other clients.

### [Install Pow][download-pow] (Mac only)

Among other things, Pow enables port proxying on your Mac, to let you route all web traffic on a particular hostname to another port on your computer. So you'll be able to access your site on `http://sitename.dev` instead of `http://localhost:8080` or `http://lvh.me:8080`. No need to remember weird urls with changing port numbers! Install [Anvil][download-anvil] to get a handy menubar extra showing all of your Pow-powered hosts.

### Clone

To get started, clone this repo, and install a required Vagrant plugin:

```
$ git clone https://github.com/SparkartGroupInc/sites.git
$ vagrant plugin install listen
```

### Up!

To start the virtual machine, simply go to the cloned repo and run:

```
$ vagrant up
```

This will boot the VM, and automatically install and configure everything that is required to run Solidus sites, a process called [Provisioning][vagrant-provisioning]: `Vagrantfile` defines a pre-built 64-bit Ubuntu 12.04.3 LTS (Precise) “box” provided by the Vagrant team. This file also defines basic configuration such as port mapping and synced folder locations, it can be updated at any time. New boxes are only downloaded to your machine the first time you provision a new VM however. Once the operating system is booted additional provisioning will occur, by running the `.solidus-devbox/provision/provision.sh` shell script. You can redo the provisioning process at any time by running `vagrant provision`.

Feel free to make updates here and push to this repo!


Development Process
-------------------

### Site commands

A few custom Vagrant commands have been added to help create and manage your Solidus sites. To see all commands:

```
$ vagrant site
```

Make sure to always be in the root of this repo when your run the commands. You never need to run commands from a site directory. For help on a specific command, use the `-h` argument. For example:

```
$ vagrant site create -h
```

### Creating a site

The easiest way to create a new Solidus site is to use the handy Solidus site template. And the easiest way to do that is to use the following command:

```
$ vagrant site create my-site
```

This will create a new sub-directory called `my-site`, initialized with a new site based on the latest [Solidus site template][solidus-site-template]. Another option is to create the directory and site yourself, from the ground up.

### Adding an existing site

To work on an existing Solidus site, copy it or clone it to a sub-directory of this repo. The name of the site will be the name of that sub-directory.

### Starting a site

Once the site has been added, start the Solidus server (which will run within the virtual machine) with this command:

```
$ vagrant site start my-site
```

You can now access the website on http://my-site.dev if you installed Pow. If not, look at the `start` command's output, the site's urls will have been displayed. Note that many sites can run at the same time.

Hint: Use your terminal autocomplete to type the site name, the trailing slash will be ignored by the vagrant command.

Hint: Site files are actually stored on your machine, not in the virtual machine. You can edit them as usual, and the server will load them from your machine. Stopping or deleting the virtual machine will not affect your files.

### Stopping a site

```
$ vagrant site stop my-site
```

### Restarting a site

```
$ vagrant site restart my-site
```

### Updating a site

As the Solidus and Solidus site templates projects progress, you'll probably want to update your sites to use the latest versions of those repos. This is done with the `update` command:

```
$ vagrant site update my-site
```

Note that this command will modify some of your site files. Make sure to review all changes applied to your files before committing those changes.

### Are my sites running?

```
$ vagrant site status
```

### Debugging a site

Run this command to follow the site's log:

```
$ vagrant site log my-site
```

### Deleting a site

Warning: you will obviously lose your local site files!

```
$ vagrant site stop my-site
$ rm -rf my-site
```

### Managing the VM

To stop the virtual machine, run:

```
$ vagrant halt
```

[See the CLI docs][vagrant-cli] for other commands.


[virtualbox]: https://www.virtualbox.org
[vagrant]: http://www.vagrantup.com
[vagrant-cli]: http://docs.vagrantup.com/v2/cli
[vagrant-folders]: http://docs.vagrantup.com/v2/synced-folders
[vagrant-networking]: http://docs.vagrantup.com/v2/networking
[vagrant-providers]: http://docs.vagrantup.com/v2/providers
[vagrant-provisioning]: http://docs.vagrantup.com/v2/provisioning/shell.html
[download-virtualbox]: https://www.virtualbox.org/wiki/Downloads
[download-vagrant]: http://downloads.vagrantup.com/tags/v1.3.5
[download-pow]: http://pow.cx
[download-anvil]: http://anvilformac.com
[solidus-site-template]: https://github.com/solidusjs/solidus-site-template
