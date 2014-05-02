require File.expand_path(File.join(File.dirname(__FILE__), 'locker', 'wrapper'))

module Mongoid
  module Locker
    module ClassMethods
      # A scope to retrieve all locked documents in the collection.
      #
      # @return [Mongoid::Criteria]
      def locked
        where :locked_until.gt => Time.now
      end

      # A scope to retrieve all unlocked documents in the collection.
      #
      # @return [Mongoid::Criteria]
      def unlocked
        any_of({:locked_until => nil}, {:locked_until.lte => Time.now})
      end

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
        # default timeout of five seconds
        @lock_timeout || 5
      end
    end

    # @api private
    def self.included mod
      mod.extend ClassMethods

      mod.field :locked_at, :type => Time
      mod.field :locked_until, :type => Time
    end


    # Returns whether the document is currently locked or not.
    #
    # @return [Boolean] true if locked, false otherwise
    def locked?
      !!(self.locked_until && self.locked_until > Time.now)
    end

    # Returns whether the current instance has the lock or not.
    #
    # @return [Boolean] true if locked, false otherwise
    def has_lock?
      @has_lock && self.locked?
    end

    # Primary method of plugin: execute the provided code once the document has been successfully locked.
    #
    # @param [Hash] opts for the locking mechanism
    # @option opts [Fixnum] :timeout The number of seconds until the lock is considered "expired" - defaults to the {ClassMethods#lock_timeout}
    # @option opts [Boolean] :wait If the document is currently locked, wait until the lock expires and try again
    # @return [void]
    def with_lock opts={}, &block
      # don't try to re-lock/unlock on recursive calls
      had_lock = self.has_lock?
      self.lock(opts) unless had_lock

      begin
        yield
      ensure
        if !had_lock && locked?
          self.unlock
        end
      end
    end


    protected

    def lock opts={}
      time = Time.now
      timeout = opts[:timeout] || self.class.lock_timeout
      expiration = time + timeout

      # lock the document atomically in the DB without persisting entire doc
      locked = Mongoid::Locker::Wrapper.update(
        self.class,
        {
          :_id => self.id,
          '$or' => [
            # not locked
            {:locked_until => nil},
            # expired
            {:locked_until => {'$lte' => time}}
          ]
        },
        {
          '$set' => {
            :locked_at => time,
            :locked_until => expiration
          }
        }
      )

      if locked
        # document successfully updated, meaning it was locked
        self.locked_at = time
        self.locked_until = expiration
        @has_lock = true
      else
        # couldn't grab lock

        if opts[:wait] && locked_until = Mongoid::Locker::Wrapper.locked_until(self)
          # doc is locked - wait until it expires
          wait_time = locked_until - Time.now
          sleep wait_time if wait_time > 0

          # only wait once
          opts.dup
          opts.delete :wait

          # reload to update with any new values
          self.reload
          # retry lock grab
          self.lock opts
        else
          raise LockError.new("could not get lock")
        end
      end
    end

    def unlock
      # unlock the document in the DB without persisting entire doc
      Mongoid::Locker::Wrapper.update(
        self.class,
        {:_id => self.id},
        {
          '$set' => {
            :locked_at => nil,
            :locked_until => nil,
          }
        }
      )

      self.locked_at = nil
      self.locked_until = nil
      @has_lock = false
    end
  end

  # Error thrown if document could not be successfully locked.
  class LockError < Exception; end
end
