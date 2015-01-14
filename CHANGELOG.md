## 1.0.0 (Jan 14, 2015)

 - Use npm scripts instead of grunt [[a626484](https://github.com/solidusjs/vagrant-solidus/commit/a626484dbd6a17122c4d5dd0d4afb39b62ce38ed)]
 - Create/update site from specific tag on cloned template repo [[1b3075b](https://github.com/solidusjs/vagrant-solidus/commit/1b3075b00a06422281ec4f321126b6d42d0e1af6)]

BREAKING CHANGES:

 - vagrant-solidus no longer manages the Solidus sites using the `grunt` command line. Instead, each site is started directly with its local Solidus bin (`./node_modules/.bin/solidus`). For sites that need to compile assets and run a file watcher, new scripts need to be added to their `package.json` files. For example, existing `grunt` tasks can still be used, but they need to be called directly with the two new special npm scripts:

  ```javascript
  {
    "scripts": {
      "build": "./node_modules/.bin/grunt build",
      "watch": "./node_modules/.bin/grunt watch"
    },
    "devDependencies": {
      "grunt": "~0.4.1",
      "grunt-cli": "~0.1.13"
    }
  }
  ```

## 0.2.1 (Nov 19, 2014)

 - Restore Vagrant >1.6.3 support [[460291e](https://github.com/solidusjs/vagrant-solidus/commit/460291e0338e3deefe87873fc1b3e70b6882bd67)]

## 0.2.0 (Sep 11, 2014)

 - Configurable ports [[280de56](https://github.com/solidusjs/vagrant-solidus/commit/280de5624e6f49fd8f56e40c4ab385b922f0169e)]

## 0.1.0 (Aug 4, 2014)

 - Add support for Solidus log server [[8d5ffb8](https://github.com/solidusjs/vagrant-solidus/commit/8d5ffb8a985013f5258676154840e200d9ae4595)]

## 0.0.2 (May 22, 2014)

 - Restrict to Vagrant 1.5.x until this is resolved: https://github.com/mitchellh/vagrant/issues/3769 [[72410cf](https://github.com/solidusjs/vagrant-solidus/commit/72410cfb07ac126be004ce6dd9abc397fbb26806)]

## 0.0.1 (May 22, 2014)

 - Initial release

BREAKING CHANGES:

 - If you have an old version of [solidus-devbox](https://github.com/solidusjs/solidus-devbox), it's simplest to reset the whole box (this will not remove your sites' files):

  ```
  $ vagrant destroy
  $ vagrant plugin install vagrant-solidus
  $ vagrant solidus-box init # Make sure to reapply your custom changes to the new Vagrantfile
  $ vagrant up
  ```
