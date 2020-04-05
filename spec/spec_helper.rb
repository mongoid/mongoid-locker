# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_group 'Libraries', 'lib/'
    track_files 'lib/**/*.rb'
    add_filter '/spec/'
  end
end

require 'mongoid-locker'
Mongoid.load! File.join(File.dirname(__FILE__), 'database.yml')

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.include LockerHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.filter_run_when_matching :focus
  config.disable_monkey_patching!
  config.raise_errors_for_deprecations!

  config.order = :random
  Kernel.srand config.seed
end

# Use to check the query conditions
log_level = ENV['LOG'].nil? ? 'INFO' : 'DEBUG'
Mongoid.logger.level = Logger.const_get(log_level)
Mongo::Logger.logger.level = Logger.const_get(log_level)
