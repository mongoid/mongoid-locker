module Mongoid
  module Locker
    module ClassMethods
      def locker_timeout_after new_time
        @locker_timeout = new_time
      end

      def locker_timeout
        @locker_timeout
      end
    end

    def self.included mod
      mod.extend ClassMethods
      mod.field :locked_at, :type => Time
      # default timeout of five seconds
      mod.instance_variable_set :@locker_timeout, 5
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
      expiration = time - self.class.locker_timeout

      # update the DB without persisting entire doc
      record = self.class.collection.find_and_modify(
        :query => {
          :_id => self.id,
          '$or' => [
            {:locked_at => nil},
            {:locked_at => {'$lte' => expiration}}
          ]
        },
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
