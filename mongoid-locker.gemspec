# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

require 'mongoid/locker/version'

Gem::Specification.new do |s|
  s.name = 'mongoid-locker'
  s.version = Mongoid::Locker::VERSION
  s.authors = ['Aidan Feldman']
  s.email = ['aidan.feldman@gmail.com']

  s.summary = 'Document-level optimistic locking for MongoDB via Mongoid.'
  s.description = 'Allows multiple processes to operate on individual documents in MongoDB while ensuring that only one can act at a time.'
  s.homepage = 'https://github.com/mongoid/mongoid-locker'
  s.license = 'MIT'

  s.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(spec)/}) }
  s.require_paths = ['lib']

  s.add_dependency 'mongoid', '>= 5.0', '< 9'
end
