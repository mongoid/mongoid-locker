module Mongoid
  module Locker
    def self.included mod
      mod.field :locked_at, :type => Time
    end

    def locked?
      !!self.locked_at
    end

    def with_lock &block
      self.lock
      begin
        yield
      ensure
        self.unlock
      end
    end


    protected

    def lock
      time = Time.now
      self.locked_at = time
      # update the DB without persisting entire doc
      record = self.class.collection.find_and_modify(
        :query => {:_id => self.id, :locked_at => nil},
        :update => {'$set' => {:locked_at => time}}
      )

      raise LockError.new("could not get lock") unless record
    end

    def unlock
      # update the DB without persisting entire doc
      self.class.collection.update({:_id => self.id}, {'$set' => {:locked_at => nil}}, {:safe => true})
      self.locked_at = nil
    end
  end

  class LockError < Exception; end
end
