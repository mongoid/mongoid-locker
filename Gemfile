# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

case ENV.fetch('MONGOID_VERSION', nil)
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

  gem 'bigdecimal', '1.3.5', platforms: :mri
  gem 'danger', require: false
  gem 'danger-changelog', require: false
  gem 'danger-pr-comment', require: false
  gem 'mongoid-compatibility'
  gem 'mongoid-history'
  gem 'mutex_m'
  gem 'rspec', '~> 3.9'
  gem 'rubocop', '1.81.1'
  gem 'rubocop-rake'
  gem 'rubocop-rspec'
  gem 'simplecov', require: false
end
