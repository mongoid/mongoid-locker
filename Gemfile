# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

case ENV['MONGOID_VERSION']
when /^9/
  gem 'mongoid', '~> 9.0'
when /^8/
  gem 'mongoid', '~> 8.0'
when /^7/
  gem 'mongoid', '~> 7.0'
when /^6/
  gem 'mongoid', '~> 6.4'
when /^5/
  gem 'mongoid', '~> 5.4'
else
  gem 'mongoid', '>= 5.0'
end

gem 'rake'

group :development do
  gem 'guard-rspec'
end

group :development, :test do
  gem 'pry-byebug', platforms: :mri

  gem 'mongoid-compatibility'
  gem 'mongoid-danger', '~> 0.2.0'
  gem 'rspec', '~> 3.9'
  gem 'rubocop', '0.81.0'
  gem 'rubocop-rspec', '1.38.1'
  gem 'simplecov', require: false
end
