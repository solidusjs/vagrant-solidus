# Vagrant plugin for Solidus sites development

This is a [Vagrant][vagrant] plugin that adds a [Solidus][solidus] provisioner and command to manage Solidus sites. It enables you to easily create, run and update Solidus sites in the virtual machine without having to setup or log into the machine itself, through the vagrant command line interface.

## Getting Started

### [Install VirtualBox][virtualbox-install]

[VirtualBox][virtualbox] is a free cross-platform virtualization app that makes it easy to simultaneously run multiple operating systems on your machine. In our usage it is merely a [provider][vagrant-provider] for Vagrant.

### [Install Vagrant][vagrant-install]

[Vagrant][vagrant] layers provisioning, file-based configuration, and a command-line interface on top of VirtualBox. This provides disposable, consistent environments for running development servers. [Synced Folders][vagrant-synced-folders] and [Networking][vagrant-networking] features make the development experience the same as if running in your own environment: your own tools and whatever ports you’d like for access via your browser and other clients.

### [Install Pow][pow] (Mac only)

Among other things, Pow enables port proxying on your Mac, to let you route all web traffic on a particular hostname to another port on your computer. So you'll be able to access your site on `http://sitename.dev` instead of `http://localhost:8081` or `http://lvh.me:8081`. No need to remember weird urls with changing port numbers! Install [Anvil][anvil] to get a handy menubar extra showing all of your Pow-powered hosts. This plugin will automatically configure Pow for your sites, if it is installed.

### Create the Vagrant environment

Using this plugin, you can easily create a `Vagrantfile` ready for Solidus:

```
$ vagrant plugin install vagrant-solidus
$ mkdir solidus
$ cd solidus
$ vagrant solidus-box init
```

### Up!

You are now ready to start the virtual machine:

```
$ vagrant up
```

This will boot the VM, and automatically install and configure everything that is required to run Solidus sites, a process called [Provisioning][vagrant-provisioning]: `Vagrantfile` defines a pre-built 64-bit Ubuntu 12.04.3 LTS (Precise) “box” provided by the Vagrant team. This file also defines basic configuration such as port mapping and synced folder locations, it can be updated at any time. New boxes are only downloaded to your machine the first time you provision a new VM however. Once the operating system is booted, this plugin will perform additional provisioning. You can redo the provisioning process at any time by running `vagrant provision`.

At this point, you are ready to work on your Solidus site!

## Development Process

A number of ports are automatically opened and forwarded to the virtual machine: `8081 to 8095` for the Solidus sites, and `35730 to 35744` for [LiveReload][livereload]. Whenever a site is started, two ports will be used for that site, so you can load them on your local browser.

A new `site` Vagrant command has been added to help create and manage your Solidus sites. To see all available sub-commands:

```
$ vagrant site
```

For help on a specific command, use the `-h` argument. For example:

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
$ cd my-site
$ vagrant site start
```

You can now access the website on http://my-site.dev if you installed Pow. If not, look at the `start` command's output, the site's urls will have been displayed. Note that many sites can run at the same time.

Hint: Site files are actually stored on your machine, not in the virtual machine. You can edit them as usual, and the server will load them from your machine. Stopping or deleting the virtual machine will not affect your files.

### Stopping a site

```
$ vagrant site stop
```

### Restarting a site

```
$ vagrant site restart
```

### Updating a site

As the Solidus and Solidus site templates projects progress, you'll probably want to update your sites to use the latest versions of those repos. This is done with the `update` command:

```
$ vagrant site update
```

Note that this command will modify some of your site files. Make sure to review all changes applied to your files before committing those changes.

### Running command line commands

If you need to run custom commands for your site, for example [Grunt tasks][gruntjs], you will need to run them in the VM itself.

Hard way (ssh into the VM and run your commands):

```
$ vagrant ssh
$ cd my-site
$ grunt my-task --option=something
$ exit
```

Easy way (use the `run` command):

```
$ vagrant site run grunt my-site --option=something
```

### Are my sites running?

```
$ vagrant site status
```

### Debugging a site

Run this command to follow the site's log:

```
$ vagrant site log
```

### Deleting a site

Warning: you will obviously lose your local site files!

```
$ vagrant site stop
$ cd ..
$ rm -rf my-site
```

### Managing the VM

To stop the virtual machine, run:

```
$ vagrant halt
```

[See the CLI docs][vagrant-cli] for other commands.

### Updating

To use the latest version of vagrant-solidus, simply update the plugin and re-initialize your `Vagrantfile`:

```
$ vagrant halt
$ vagrant plugin update vagrant-solidus
$ vagrant solidus-box init
$ vagrant up
```

## Troubleshooting ##

### Windows: 'ssh' executable not found

Vagrant needs an `ssh.exe` executable to log into the virtual machine when running `vagrant ssh`. Windows doesn't provide such an executable by default, but Git does. The easiest way to fix this problem is by adding Git's `bin` path to the system's `PATH` environment variable. In the Start menu, search for "system environment variables". Then locate the `PATH` system environment variable, click `Edit` and add Git's `bin` path (probably located in `C:\Program Files (x86)\Git\bin`). Note that you will need to restart your Command Prompt for the changes to take effect. Also, note that Git's own executables like `find.exe` will be now be used instead of Windows' default executables.

### Resetting the VM

If your virtual machine is in a weird state, the simplest solution is sometimes to rebuild it. All you need to do is destroy the VM and rebuild. This process will not delete your sites files, since they are hosted on your machine, not in the virtual machine.

```
$ vagrant destroy
$ vagrant up
```

### Adding or changing the forwarded ports

When a site is started, it requires 3 forwarded ports for the Solidus server, the log server and LiveReload. By default, 45 ports are forwarded when the box is started. Once a site has been started, its used ports will be reserved for later use. If you run out of ports, or if a default port is already used by another application on your machine, you can manage them directly in the Vagrantfile, with the following config variables, which should be arrays of available ports. Note that the box should be reloaded if those values are changed.

* `config.solidus.site_ports`
* `config.solidus.livereload_ports`
* `config.solidus.log_server_ports`

It's also possible to remove ports reserved by older unused sites. The reserved ports are listed in this file: `.vagrant-solidus/data/sites.json`.

[virtualbox]: https://www.virtualbox.org
[virtualbox-install]: https://www.virtualbox.org/wiki/Downloads
[vagrant]: http://www.vagrantup.com
[vagrantfile]: https://docs.vagrantup.com/v2/vagrantfile/
[vagrant-provider]: http://docs.vagrantup.com/v2/providers
[vagrant-install]: http://www.vagrantup.com/download-archive/v1.5.4.html
[vagrant-synced-folders]: http://docs.vagrantup.com/v2/synced-folders/index.html
[vagrant-networking]: http://docs.vagrantup.com/v2/networking/index.html
[vagrant-provisioning]: http://docs.vagrantup.com/v2/provisioning/index.html
[solidus]: https://github.com/solidusjs/solidus
[pow]: http://pow.cx
[anvil]: http://anvilformac.com
[livereload]: http://livereload.com
[solidus-site-template]: https://github.com/solidusjs/solidus-site-template
[gruntjs]: http://gruntjs.com
[vagrant-cli]: http://docs.vagrantup.com/v2/cli
