lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mongoid/locker/version'

Gem::Specification.new do |spec|
  spec.name = 'mongoid-locker'
  spec.version = Mongoid::Locker::VERSION
  spec.authors = ['Aidan Feldman']
  spec.email = ['aidan.feldman@gmail.com']

  spec.summary = 'Document-level locking for MongoDB via Mongoid.'
  spec.description = 'Allows multiple processes to operate on individual documents in MongoDB while ensuring that only one can act at a time.'
  spec.homepage = 'https://github.com/mongoid/mongoid-locker'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'mongoid', '>= 2.8'
  spec.add_runtime_dependency 'mongoid-compatibility', '>= 0.4.1'
end
