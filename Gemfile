source 'http://rubygems.org'

gem 'mongoid', '>= 2.4', '<= 3.1'


# groups need to be copied to gemfiles/*.gemfile

group :development do
  gem 'rspec', '~> 2.8'
  gem 'bundler', '~> 1.1'
  gem 'jeweler', '~> 1.8'

  gem 'guard-rspec'
end

group :development, :test do
  gem 'bson_ext', :platforms => :ruby

  gem 'rake'
  # v0.4.1 doesn't support multiple group names
  gem 'appraisal', :git => 'git://github.com/thoughtbot/appraisal.git', :ref => 'ad2aeb99649f6a78f78be5009fb50306f06eaa9f'
end
