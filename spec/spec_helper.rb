$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'mongoid-locker'
require 'mongoid/compatibility'

ENV['RACK_ENV'] = 'test'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

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
  elsif Mongoid::Compatibility::Version.mongoid5?
    Mongoid.logger.level = Logger::INFO
    Mongo::Logger.logger.level = Logger::INFO
  else
    Mongoid.logger.level = Logger::INFO
    Moped.logger.level = Logger::INFO if defined? Moped
  end
end
