# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid/locker/version'

Gem::Specification.new do |spec|
  spec.name = 'mongoid-locker'
  spec.version = Mongoid::Locker::VERSION
  spec.authors = ['Aidan Feldman']
  spec.email = ['aidan.feldman@gmail.com']

  spec.summary = 'Document-level locking for MongoDB via Mongoid.'
  spec.description = 'Allows multiple processes to operate on individual documents in MongoDB while ensuring that only one can act at a time.'
  spec.homepage = 'https://github.com/afeld/mongoid-locker'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'mongoid', '>= 2.8', '< 5.0'

  spec.add_development_dependency 'bundler', '~> 1.1'
  spec.add_development_dependency 'guard-rspec', '~> 4.5'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rb-fsevent', '~> 0.9.1'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '= 0.29.1'
end
