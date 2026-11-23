# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

case ENV.fetch('MONGOID_VERSION', nil)
when /^8/
  gem 'mongoid', '~> 8.0'
when /^7/
  gem 'mongoid', '~> 7.0'
when /^6/
  gem 'mongoid', '~> 6.4'
when /^5/
  gem 'mongoid', '~> 5.4'
else
  gem 'mongoid', '~> 9.0'
end

gem 'base64'
gem 'benchmark'
gem 'mutex_m'
gem 'ostruct'
gem 'rake'

group :development do
  gem 'guard-rspec'
end

group :development, :test do
  if ENV.fetch('MONGOID_VERSION', '').start_with?('5') && RUBY_ENGINE == 'ruby'
    gem 'bigdecimal', '~> 1.3.5'
  else
    gem 'bigdecimal'
  end
  gem 'pry-byebug', platforms: :mri

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.7')
    gem 'danger', require: false
    gem 'danger-changelog', require: false
    gem 'danger-pr-comment', require: false
  end
  gem 'mongoid-compatibility'
  gem 'mongoid-history'
  gem 'rspec', '~> 3.9'
  gem 'simplecov', require: false
  if RUBY_ENGINE == 'ruby' && Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')
    gem 'rubocop', '~> 1.92'
    gem 'rubocop-md', '~> 3.0', require: false
    gem 'rubocop-prose', '~> 0.2', require: false
    gem 'rubocop-rake', '~> 0.7', require: false
    gem 'rubocop-rspec', '~> 3.10', require: false
    gem 'rubocop-spellcheck', '~> 0.2', require: false
    gem 'rubocop-yaml', '~> 0.1.0', require: false
  end
end
