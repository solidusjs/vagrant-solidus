# Vagrant plugin for Solidus sites development

This is a [Vagrant][vagrant] plugin that adds a [Solidus][solidus] provisioner and command to manage Solidus sites. It enables you to easily create, run and update Solidus sites in the virtual machine without having to setup or log into the machine itself, through the vagrant command line interface.

## Getting Started

### Install vagrant-solidus-plugin

```
$ vagrant plugin install vagrant-solidus-plugin
```

### [Install Pow][pow] (Mac only)

Among other things, Pow enables port proxying on your Mac, to let you route all web traffic on a particular hostname to another port on your computer. So you'll be able to access your site on `http://sitename.dev` instead of `http://localhost:8081` or `http://lvh.me:8081`. No need to remember weird urls with changing port numbers! Install [Anvil][anvil] to get a handy menubar extra showing all of your Pow-powered hosts. This plugin will automatically configure Pow for your sites, if it is installed.

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

To use the latest versions of vagrant-solidus-box and vagrant-solidus-plugin, run this from the cloned repo directory:

```
$ vagrant halt
$ git pull
$ vagrant plugin update vagrant-solidus-plugin
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


[vagrant]: http://www.vagrantup.com
[solidus]: https://github.com/solidusjs/solidus
[pow]: http://pow.cx
[anvil]: http://anvilformac.com
[livereload]: http://livereload.com
[solidus-site-template]: https://github.com/solidusjs/solidus-site-template
[gruntjs]: http://gruntjs.com
[vagrant-cli]: http://docs.vagrantup.com/v2/cli
