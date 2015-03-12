source 'http://rubygems.org'

case version = ENV['MONGOID_VERSION'] || '~> 4.0'
when /4/
  gem 'mongoid', '~> 4.0'
when /3/
  gem 'mongoid', '~> 3.1'
when /2/
  gem 'bson_ext', platforms: :ruby
  gem 'mongoid', '~> 2.8'
else
  gem 'mongoid', version
end

group :development do
  gem 'rspec', '~> 3.0'
  gem 'bundler', '~> 1.1'
  gem 'jeweler', '~> 1.8'

  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1'
end

group :development, :test do
  gem 'rake'
  gem 'rubocop', '0.29.1'
end
