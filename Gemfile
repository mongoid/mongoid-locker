source 'http://rubygems.org'

gem 'mongoid', '>= 2.4', '<= 3.1'


# groups need to be copied to gemfiles/*.gemfile

group :development do
  gem 'rspec', '~> 2.8'
  gem 'bundler', '~> 1.1'
  gem 'jeweler', '~> 1.8'

  gem 'guard-rspec'
  gem 'rb-fsevent', '~> 0.9.1'
end

group :development, :test do
  gem 'bson_ext', :platforms => :ruby

  gem 'rake'
  gem 'appraisal', '~> 0.5.0'
end
