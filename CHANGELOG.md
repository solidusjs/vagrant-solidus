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
