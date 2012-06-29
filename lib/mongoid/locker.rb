module Mongoid
  module Locker
    def self.included mod
      mod.field :locked_at, type: Time
    end

    def locked?
      !!locked_at
    end

    # note this saves the user before and after the block is executed
    def with_lock &block
      self.locked_at = Time.now
      self.save!

      yield

      self.locked_at = nil
      self.save!
    end
  end
end
