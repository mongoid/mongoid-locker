$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

if ENV['COVERAGE'] == 'true'
  require 'simplecov'
  SimpleCov.start do
    add_group 'Libraries', 'lib/'
    track_files 'lib/**/*.rb'
  end
end

require 'rspec'
require 'mongoid-locker'

ENV['RACK_ENV'] = 'test'

RSpec.configure do |config|
  version = Mongoid::VERSION.split('.')[0]
  Mongoid.load! File.join(File.dirname(__FILE__), "database#{version}.yml")

  config.raise_errors_for_deprecations!

  config.order = :random

  config.before do
    Mongoid::Locker.reset!
  end

  # use to check the query conditions
  log_level = ENV['LOG'].nil? ? 'INFO' : 'DEBUG'
  Mongoid.logger.level = Logger.const_get(log_level)
  Mongo::Logger.logger.level = Logger.const_get(log_level) if defined? Mongo
  Moped.logger.level = Logger.const_get(log_level) if defined? Moped
end
