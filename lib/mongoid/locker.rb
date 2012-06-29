module Mongoid
  module Locker
    def self.included mod
      mod.field :locked_at, type: Time
    end

    def locked?
      !!locked_at
    end
  end
end
