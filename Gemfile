source 'http://rubygems.org'
# Add dependencies required to use your gem here.
# Example:
#   gem 'activesupport', '>= 2.3.5'

gem 'mongoid', '>= 2.4', '<= 3.1'

# Add dependencies to develop your gem here.
# Include everything needed to run rake, tests, features, etc.
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
