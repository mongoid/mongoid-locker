# encoding: utf-8

require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'appraisal'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "mongoid-locker"
  gem.homepage = "http://github.com/afeld/mongoid-locker"
  gem.license = "MIT"
  gem.summary = "Document-level locking for MongoDB via Mongoid"
  gem.description = %Q{Allows multiple processes to operate on individual documents in MongoDB while ensuring that only one can act at a time.}
  gem.email = "aidan.feldman@gmail.com"
  gem.authors = ["Aidan Feldman"]
  gem.files.exclude 'demo'
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec
