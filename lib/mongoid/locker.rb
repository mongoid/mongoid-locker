module Mongoid
  module Locker
    module ClassMethods
      # Set the default lock timeout for this class.  Note this only applies to new locks.  Defaults to five seconds.
      #
      # @param [Fixnum] new_time the default number of seconds until a lock is considered "expired", in seconds
      # @return [void]
      def timeout_lock_after new_time
        @lock_timeout = new_time
      end

      # Retrieve the lock timeout default for this class.
      #
      # @return [Fixnum] the default number of seconds until a lock is considered "expired", in seconds
      def lock_timeout
        @lock_timeout
      end
    end

    # @api private
    def self.included mod
      mod.extend ClassMethods

      mod.field :locked_at, :type => Time
      mod.field :locked_until, :type => Time

      # default timeout of five seconds
      mod.instance_variable_set :@lock_timeout, 5
    end


    # Returns whether the document is currently locked or not.
    #
    # @return [Boolean] true if locked, false otherwise
    def locked?
      self.locked_until && self.locked_until > Time.now
    end

    # Primary method of plugin: execute the provided code once the document has been successfully locked.
    #
    # @param [Hash] opts for the locking mechanism
    # @option opts [Fixnum] :timeout The number of seconds until the lock is considered "expired" - defaults to the {ClassMethods#lock_timeout}
    # @option opts [Boolean] :wait If the document is currently locked, wait until the lock expires and try again
    # @return [void]
    def with_lock opts={}, &block
      self.lock opts
      begin
        yield
      ensure
        self.unlock
      end
    end


    protected

    def lock opts={}
      coll = self.class.collection
      time = Time.now
      timeout = opts[:timeout] || self.class.lock_timeout
      expiration = time + timeout

      # lock the document atomically in the DB without persisting entire doc
      record = coll.find_and_modify(
        :query => {
          :_id => self.id,
          '$or' => [
            # not locked
            {:locked_until => nil},
            # expired
            {:locked_until => {'$lte' => time}}
          ]
        },
        :update => {
          '$set' => {
            :locked_at => time,
            :locked_until => expiration
          }
        }
      )

      if record
        # lock successful
        self.locked_at = time
        self.locked_until = expiration
      else
        # couldn't grab lock

        existing_query = {
          :_id => self.id,
          :locked_until => {'$exists' => true}
        }

        if opts[:wait] && existing = coll.find(existing_query, :limit => 1).first
          # doc is locked - wait until it expires
          wait_time = existing.locked_until - Time.now
          sleep wait_time if wait_time > 0

          # only wait once
          opts.dup
          opts.delete :wait

          # retry lock grab
          self.lock opts
        else
          raise LockError.new("could not get lock")
        end
      end
    end

    def unlock
      # unlock the document in the DB without persisting entire doc
      self.class.collection.update({:_id => self.id}, {
        '$set' => {
          :locked_at => nil,
          :locked_until => nil,
        }
      }, {:safe => true})

      self.locked_at = nil
      self.locked_until = nil
    end
  end

  # Error thrown if document could not be successfully locked.
  class LockError < Exception; end
end
