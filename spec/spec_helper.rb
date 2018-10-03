$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'simplecov'
SimpleCov.start do
  add_group 'Libraries', 'lib/'
  track_files 'lib/**/*.rb'
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
  if ENV['LOG']
    Mongoid.logger.level = Logger::DEBUG
    Moped.logger.level = Logger::DEBUG if defined? Moped
  elsif version == '5'
    Mongoid.logger.level = Logger::INFO
    Mongo::Logger.logger.level = Logger::INFO
  else
    Mongoid.logger.level = Logger::INFO
    Moped.logger.level = Logger::INFO if defined? Moped
  end
end
