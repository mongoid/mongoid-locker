source 'http://rubygems.org'

case ENV['MONGOID_VERSION']
when /^7/
  gem 'mongoid', '~> 7.0'
when /^6/
  gem 'mongoid', '~> 6.4'
when /^5/
  gem 'mongoid', '~> 5.4'
when /^4/
  gem 'mongoid', '~> 4.0'
else
  gem 'mongoid', '>= 4.0'
end

gemspec

group :development do
  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1'
end

group :development, :test do
  gem 'mongoid-compatibility'
  gem 'mongoid-danger', '~> 0.1.1'
  gem 'rack', '~> 1.5'
  gem 'rake', '11.3.0'
  gem 'rspec', '~> 3.0'
  gem 'rubocop'
  gem 'simplecov', require: false
end
