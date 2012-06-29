# More info at https://github.com/guard/guard#readme

guard 'rspec', :cli => '--drb', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { "spec" }
  watch('spec/spec_helper.rb')  { "spec" }
end
