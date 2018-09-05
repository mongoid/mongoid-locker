require 'mongoid/compatibility'

if Mongoid::Compatibility::Version.mongoid7?
  require 'mongoid/locker/wrapper7'
elsif Mongoid::Compatibility::Version.mongoid6?
  require 'mongoid/locker/wrapper6'
elsif Mongoid::Compatibility::Version.mongoid5?
  require 'mongoid/locker/wrapper5'
elsif Mongoid::Compatibility::Version.mongoid4?
  require 'mongoid/locker/wrapper4'
else
  raise 'incompatible Mongoid version'
end
