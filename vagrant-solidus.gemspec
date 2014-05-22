# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-solidus/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-solidus"
  spec.version       = VagrantPlugins::Solidus::VERSION
  spec.authors       = ["Joannic Laborde"]
  spec.email         = ["joannic@sparkart.com"]
  spec.summary       = "This plugin provides a provisioner and a `site` command that allows Solidus sites to be managed by Vagrant."
  spec.homepage      = "https://github.com/solidusjs/vagrant-solidus"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
