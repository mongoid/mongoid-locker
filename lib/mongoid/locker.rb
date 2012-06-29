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
      self.locked_at && self.locked_at > Time.now - self.class.locker_timeout
    end

    def with_lock wait=false, &block
      self.lock wait
      begin
        yield
      ensure
        self.unlock
      end
    end


    protected

    def lock wait=false
      coll = self.class.collection
      time = Time.now
      self.locked_at = time
      timeout = self.class.locker_timeout
      expiration = time - timeout

      # update the DB without persisting entire doc
      record = coll.find_and_modify(
        :query => {
          :_id => self.id,
          '$or' => [
            # not locked
            {:locked_at => nil},
            # expired
            {:locked_at => {'$lte' => expiration}}
          ]
        },
        :update => {'$set' => {:locked_at => time}}
      )

      unless record
        # couldn't grab lock

        existing_query = {
          :_id => self.id,
          :locked_at => {'$exists' => true}
        }

        if wait && existing = coll.find(existing_query, :limit => 1).first
          # doc is locked - wait until it expires
          wait_time = timeout - (Time.now - existing.locked_at)
          sleep wait_time if wait_time > 0

          # retry lock grab
          self.lock
        else
          raise LockError.new("could not get lock")
        end
      end
    end

    def unlock
      # update the DB without persisting entire doc
      self.class.collection.update({:_id => self.id}, {'$set' => {:locked_at => nil}}, {:safe => true})
      self.locked_at = nil
    end
  end

  class LockError < Exception; end
end
