# More info at https://github.com/guard/guard#readme

guard 'rspec', :version => 2 do
  watch(%r{^spec/.+_spec\.rb$})

  watch('Gemfile')              { "spec" }
  watch('Gemfile.lock')         { "spec" }
  watch(%r{^lib/(.+)\.rb$})     { "spec" }
  watch('spec/spec_helper.rb')  { "spec" }
end

guard 'yard', :port => '8808' do
  watch(%r{^lib/(.+)\.rb$})

  callback(:start_end) { `open http://localhost:8808` }
end
