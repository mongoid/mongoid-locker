if %w[4 5 6 7].include?(version = Mongoid::VERSION.split('.')[0])
  require "mongoid/locker/wrapper#{version}"
else
  raise "Incompatible Mongoid #{version} version"
end
