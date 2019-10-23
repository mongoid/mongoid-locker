# frozen_string_literal: true

# More info at https://github.com/guard/guard#readme

guard :rspec, cmd: 'bundle exec rspec', all_on_start: true do
  require 'guard/rspec/dsl'
  dsl = Guard::RSpec::Dsl.new(self)

  # RSpec files
  rspec = dsl.rspec
  watch(rspec.spec_helper) { rspec.spec_dir }
  watch(rspec.spec_support) { rspec.spec_dir }
  watch(rspec.spec_files) { rspec.spec_dir }

  watch('Gemfile.lock') { rspec.spec_dir }

  ruby = dsl.ruby
  watch(ruby.lib_files) { rspec.spec_dir }
end
