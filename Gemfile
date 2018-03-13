source 'http://rubygems.org'

case ENV['MONGOID_VERSION']
when /^7/
  gem 'mongoid', '~> 7.0'
when /^6/
  gem 'mongoid', '~> 6.0'
when /^5/
  gem 'mongoid', '~> 5.0'
when /^4/
  gem 'mongoid', '~> 4.0'
when /^3/
  gem 'mongoid', '~> 3.1'
when /^2/
  gem 'bson_ext', platforms: :ruby
  gem 'mongoid', '~> 2.8'
else
  gem 'mongoid', '>= 2.8', '< 7.0'
end

gemspec

group :development do
  gem 'bundler', '~> 1.1'
  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1'
end

group :development, :test do
  gem 'mongoid-compatibility'
  gem 'rack', '~> 1.5'
  gem 'rspec', '~> 3.0'
  gem 'rake', '11.3.0'
  gem 'rubocop', '0.29.1'
  gem 'mongoid-danger', '~> 0.1.1'
end
