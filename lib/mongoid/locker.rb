module Mongoid
  module Locker
    class << self
      def inherited mod
        mod.include Mongoid::Document # in case they forgot
      end
    end
  end
end
