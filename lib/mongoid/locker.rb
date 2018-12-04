require 'securerandom'
require File.expand_path(File.join(File.dirname(__FILE__), 'locker', 'version'))
require File.expand_path(File.join(File.dirname(__FILE__), 'locker', 'wrapper'))

module Mongoid
  module Locker
    # The field names used by default.
    @locked_at_field     = :locked_at
    @locked_until_field  = :locked_until
    @locked_name_field   = :locked_name

    # Error thrown if document could not be successfully locked.
    class LockError < RuntimeError; end

    module ClassMethods
      # A scope to retrieve all locked documents in the collection.
      #
      # @return [Mongoid::Criteria]
      def locked
        where locked_until_field.gt => Time.now.utc
      end

      # A scope to retrieve all unlocked documents in the collection.
      #
      # @return [Mongoid::Criteria]
      def unlocked
        any_of({ locked_until_field => nil }, locked_until_field.lte => Time.now.utc)
      end

      # Set the default lock timeout for this class.  Note this only applies to new locks.  Defaults to five seconds.
      #
      # @param [Fixnum] new_time the default number of seconds until a lock is considered "expired", in seconds
      # @return [void]
      def timeout_lock_after(new_time)
        @lock_timeout = new_time
      end

      # Retrieve the lock timeout default for this class.
      #
      # @return [Fixnum] the default number of seconds until a lock is considered "expired", in seconds
      def lock_timeout
        # default timeout of five seconds
        @lock_timeout || 5
      end

      # Set locked_at_field, locked_until_field, and locked_name_field names for this class.
      def locker(locked_at_field: nil, locked_until_field: nil, locked_name_field: nil)
        class_variable_set(:@@locked_at_field, locked_at_field) if locked_at_field
        class_variable_set(:@@locked_until_field, locked_until_field) if locked_until_field
        class_variable_set(:@@locked_name_field, locked_name_field) if locked_name_field
      end

      # Returns field name used to set locked at time for this class.
      def locked_at_field
        class_variable_get(:@@locked_at_field)
      end

      # Returns field name used to set locked until time for this class.
      def locked_until_field
        class_variable_get(:@@locked_until_field)
      end

      # Returns field name used to set name of a lock for this class.
      def locked_name_field
        class_variable_get(:@@locked_name_field)
      end

      # Returns random lock name for this class. It uses Mongoid::Locker.random_lock_name by default.
      def random_lock_name
        Mongoid::Locker.random_lock_name
      end
    end

    class << self
      attr_accessor :locked_at_field, :locked_until_field, :locked_name_field

      # @api private
      def included(mod)
        mod.extend ClassMethods

        mod.class_variable_set(:@@locked_at_field, locked_at_field)
        mod.class_variable_set(:@@locked_until_field, locked_until_field)
        mod.class_variable_set(:@@locked_name_field, locked_name_field)

        mod.send(:define_method, :locked_at_field) { mod.class_variable_get(:@@locked_at_field) }
        mod.send(:define_method, :locked_until_field) { mod.class_variable_get(:@@locked_until_field) }
        mod.send(:define_method, :locked_name_field) { mod.class_variable_get(:@@locked_name_field) }
      end

      # Sets configuration using a block
      #
      # Mongoid::Locker.configure do |config|
      #   config.locked_at_field = :mongoid_locker_locked_at
      #   config.locked_until_field = :mongoid_locker_locked_until
      #   config.locked_name_field = :mongoid_locker_locked_name
      # end
      def configure
        yield(self) if block_given?
      end

      # Resets to default configuration.
      def reset!
        # The field names used by default.
        @locked_at_field     = :locked_at
        @locked_until_field  = :locked_until
        @locked_name_field   = :locked_name
      end

      # Generates random hexadecimal string.
      #
      # @return [String]
      def random_lock_name
        SecureRandom.hex(4)
      end
    end

    # Returns whether the document is currently locked or not.
    #
    # @return [Boolean] true if locked, false otherwise
    def locked?
      !!(self[locked_until_field] && self[locked_until_field] > Time.now.utc)
    end

    # Returns whether the current instance has the lock or not.
    #
    # @return [Boolean] true if locked, false otherwise
    def has_lock?
      !!(@has_lock && locked?)
    end

    # Primary method of plugin: execute the provided code once the document has been successfully locked.
    #
    # @param [Hash] opts for the locking mechanism
    # @option opts [Fixnum] :timeout The number of seconds until the lock is considered "expired" - defaults to the {ClassMethods#lock_timeout}
    # @option opts [Fixnum] :retries If the document is currently locked, the number of times to retry - defaults to 0
    # @option opts [Float] :retry_sleep How long to sleep between attempts to acquire lock - defaults to time left until lock is available
    # @option opts [Boolean] :wait (deprecated) If the document is currently locked, wait until the lock expires and try again - defaults to false. If set, :retries will be ignored
    # @option opts [Boolean] :reload After acquiring the lock, reload the document - defaults to true
    # @return [void]
    def with_lock(opts = {})
      unless !persisted? || (had_lock = has_lock?)
        if opts[:wait]
          opts[:retries] = 1
          warn 'WARN: `:wait` option for Mongoid::Locker is deprecated - use `retries: 1` instead.'
        end

        lock(opts)
      end

      begin
        yield
      ensure
        unlock if !had_lock && locked?
      end
    end

    protected

    def acquire_lock(opts = {})
      time = Time.now.utc
      timeout = opts[:timeout] || self.class.lock_timeout
      expiration = time + timeout

      # lock the document atomically in the DB without persisting entire doc
      locked = Mongoid::Locker::Wrapper.update(
        self.class,
        {
          :_id => id,
          '$or' => [
            # not locked
            { locked_until_field => nil },
            # expired
            { locked_until_field => { '$lte' => time } }
          ]
        },
        '$set' => {
          locked_at_field => time,
          locked_until_field => expiration,
          locked_name_field => opts[:locked_name]
        }
      )

      if locked
        # document successfully updated, meaning it was locked
        self[locked_at_field] = time
        self[locked_until_field] = expiration
        self[locked_name_field] = opts[:locked_name]
        reload unless opts[:reload] == false
        @has_lock = true
      else
        @has_lock = false
      end
    end

    def lock(opts = {})
      opts = { retries: 0 }.merge(opts)

      attempts_left = opts[:retries] + 1
      retry_sleep = opts[:retry_sleep]
      iteration = 0
      lock_name = self.class.random_lock_name

      loop do
        opts[:locked_name] = "#{lock_name}##{iteration}"

        return if acquire_lock(opts)

        attempts_left -= 1
        iteration += 1

        raise LockError, 'could not get lock' unless attempts_left > 0

        # if not passed a retry_sleep value, we sleep for the remaining life of the lock
        unless retry_sleep
          locked_until = Mongoid::Locker::Wrapper.locked_until(self)
          # the lock might be released since the last check so make another attempt
          next unless locked_until

          retry_sleep = locked_until - Time.now.utc
        end

        sleep retry_sleep if retry_sleep > 0
      end
    end

    def unlock
      # unlock the document in the DB without persisting entire doc
      Mongoid::Locker::Wrapper.update(
        self.class,
        { _id: id },
        '$set' => {
          locked_at_field => nil,
          locked_until_field => nil,
          locked_name_field => nil
        }
      )

      self.attributes = { locked_at_field => nil, locked_until_field => nil, locked_name_field => nil } unless destroyed?
      @has_lock = false
    end
  end
end
