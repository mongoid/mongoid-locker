# frozen_string_literal: true

require 'forwardable'
require 'securerandom'

module Mongoid
  module Locker
    class << self
      # Available parameters for +Mongoid::Locker+ module, a class where the module is included and it's instances.
      MODULE_METHODS = %i[
        locking_name_field
        locked_at_field
        maximum_backoff
        lock_timeout
        locker_write_concern
        backoff_algorithm
        locking_name_generator
      ].freeze

      attr_accessor(*MODULE_METHODS)

      # Generates secure random string of +name#attempt+ format.
      #
      # @example
      #   Mongoid::Locker.secure_locking_name(doc, { attempt: 1 })
      #   #=> "zLmulhOy9yn_NE886OWNYw#1"
      #
      # @param doc [Mongoid::Document]
      # @param opts [Hash] (see #with_lock)
      # @return [String]
      def secure_locking_name(_doc, opts)
        "#{SecureRandom.urlsafe_base64}##{opts[:attempt]}"
      end

      # Returns random number of seconds depend on passed options.
      #
      # @example
      #   Mongoid::Locker.exponential_backoff(doc, { attempt: 0 })
      #   #=> 1.2280675023095662
      #   Mongoid::Locker.exponential_backoff(doc, { attempt: 1 })
      #   #=> 2.901641863236713
      #   Mongoid::Locker.exponential_backoff(doc, { attempt: 2 })
      #   #=> 4.375030664612267
      #
      # @param _doc [Mongoid::Document]
      # @param opts [Hash] (see #with_lock)
      # @return [Float]
      def exponential_backoff(_doc, opts)
        2**opts[:attempt] + rand
      end

      # Returns time in seconds remaining to complete the lock of the provided document. Makes requests to the database.
      #
      # @example
      #   Mongoid::Locker.locked_at_backoff(doc, opts)
      #   #=> 2.32422359
      #
      # @param doc [Mongoid::Document]
      # @param opts [Hash] (see #with_lock)
      # @return [Float | Integer]
      # @return [0] if the provided document is not locked
      def locked_at_backoff(doc, opts)
        return doc.maximum_backoff if opts[:attempt] * doc.lock_timeout >= doc.maximum_backoff

        locked_at = Wrapper.locked_at(doc).to_f
        return 0 unless locked_at > 0

        current_time = Wrapper.current_mongodb_time(doc.class).to_f
        delay = doc.lock_timeout - (current_time - locked_at)

        delay < 0 ? 0 : delay + rand
      end

      # Sets configuration using a block.
      #
      # @example
      #   Mongoid::Locker.configure do |config|
      #     config.locking_name_field     = :locking_name
      #     config.locked_at_field        = :locked_at
      #     config.lock_timeout           = 5
      #     config.locker_write_concern   = { w: 1 }
      #     config.maximum_backoff        = 60.0
      #     config.backoff_algorithm      = :exponential_backoff
      #     config.locking_name_generator = :secure_locking_name
      #   end
      def configure
        yield(self) if block_given?
      end

      # Resets to default configuration.
      #
      # @example
      #   Mongoid::Locker.reset!
      def reset!
        # The parameters used by default.
        self.locking_name_field     = :locking_name
        self.locked_at_field        = :locked_at
        self.lock_timeout           = 5
        self.locker_write_concern   = { w: 1 }
        self.maximum_backoff        = 60.0
        self.backoff_algorithm      = :exponential_backoff
        self.locking_name_generator = :secure_locking_name
      end

      # @api private
      def included(klass)
        klass.extend(Forwardable) unless klass.ancestors.include?(Forwardable)

        klass.extend ClassMethods
        klass.singleton_class.instance_eval { attr_accessor(*MODULE_METHODS) }

        klass.locking_name_field = locking_name_field
        klass.locked_at_field = locked_at_field
        klass.lock_timeout = lock_timeout
        klass.locker_write_concern = locker_write_concern
        klass.maximum_backoff = maximum_backoff
        klass.backoff_algorithm = backoff_algorithm
        klass.locking_name_generator = locking_name_generator

        klass.def_delegators(klass, *MODULE_METHODS)
        klass.singleton_class.delegate(*(methods(false) - MODULE_METHODS.flat_map { |method| [method, "#{method}=".to_sym] } - %i[included reset! configure]), to: self)
      end
    end

    reset!

    module ClassMethods
      # A scope to retrieve all locked documents in the collection.
      #
      # @example
      #   Account.count
      #   #=> 1717
      #   Account.locked.count
      #   #=> 17
      #
      # @return [Mongoid::Criteria]
      def locked
        where(
          '$and': [
            { locking_name_field => { '$exists': true, '$ne': nil } },
            { locked_at_field => { '$exists': true, '$ne': nil } },
            { '$where': "new Date() - this.#{locked_at_field} < #{lock_timeout * 1000}" }
          ]
        )
      end

      # A scope to retrieve all unlocked documents in the collection.
      #
      # @example
      #   Account.count
      #   #=> 1717
      #   Account.unlocked.count
      #   #=> 1700
      #
      # @return [Mongoid::Criteria]
      def unlocked
        where(
          '$or': [
            {
              '$or': [
                { locking_name_field => { '$exists': false } },
                { locked_at_field => { '$exists': false } }
              ]
            },
            {
              '$or': [
                { locking_name_field => { '$eq': nil } },
                { locked_at_field => { '$eq': nil } }
              ]
            },
            {
              '$where': "new Date() - this.#{locked_at_field} >= #{lock_timeout * 1000}"
            }
          ]
        )
      end

      # Unlock all locked documents in the collection. Sets locking_name_field and locked_at_field fields to nil. Returns number of unlocked documents.
      #
      # @example
      #   Account.unlock_all
      #   #=> 17
      #   Account.locked.unlock_all
      #   #=> 0
      #
      # @return [Integer]
      def unlock_all
        update_all('$set': { locking_name_field => nil, locked_at_field => nil }).modified_count
      end

      # Sets configuration for this class.
      #
      # @example
      #   locker locking_name_field: :locker_locking_name,
      #          locked_at_field: :locker_locked_at,
      #          lock_timeout: 3,
      #          locker_write_concern: { w: 1 },
      #          maximum_backoff: 30.0,
      #          backoff_algorithm: :locked_at_backoff,
      #          locking_name_generator: :custom_locking_name
      #
      # @param locking_name_field [Symbol]
      # @param locked_at_field [Symbol]
      # @param maximum_backoff [Float, Integer]
      # @param lock_timeout [Float, Integer]
      # @param locker_write_concern [Hash]
      # @param backoff_algorithm [Symbol]
      # @param locking_name_generator [Symbol]
      def locker(**params)
        invalid_parameters = params.keys - Mongoid::Locker.singleton_class.const_get('MODULE_METHODS')
        raise Mongoid::Locker::Errors::InvalidParameter.new(self.class, invalid_parameters.first) unless invalid_parameters.empty?

        params.each_pair do |key, value|
          send("#{key}=", value)
        end
      end
    end

    # Returns whether the document is currently locked in the database or not.
    #
    # @example
    #   document.locked?
    #   #=> false
    #
    # @return [Boolean] true if locked, false otherwise
    def locked?
      persisted? && self.class.where(_id: id).locked.limit(1).count == 1
    end

    # Returns whether the current instance has the lock or not.
    #
    # @example
    #   document.has_lock?
    #   #=> false
    #
    # @return [Boolean] true if locked, false otherwise
    def has_lock?
      @has_lock || false
    end

    # Executes the provided code once the document has been successfully locked. Otherwise, raises error after the number of retries to lock the document is exhausted or it is reached {ClassMethods#maximum_backoff} limit (depending what comes first).
    #
    # @example
    #   document.with_lock(reload: true, retries: 3) do
    #     document.quantity = 17
    #     document.save!
    #   end
    #
    # @param [Hash] opts for the locking mechanism
    # @option opts [Fixnum] :retries (INFINITY) If the document is currently locked, the number of times to retry
    # @option opts [Boolean] :reload (true) After acquiring the lock, reload the document
    # @option opts [Integer] :attempt (0) Increment with each retry (not accepted by the method)
    # @option opts [String] :locking_name Generate with each retry (not accepted by the method)
    def with_lock(**opts)
      opts = opts.dup
      opts[:retries] ||= Float::INFINITY
      opts[:reload] = opts[:reload] != false

      acquire_lock(opts) if persisted? && (had_lock = !has_lock?)

      begin
        yield
      ensure
        unlock!(opts) if had_lock
      end
    end

    protected

    def acquire_lock(opts)
      opts[:attempt] = 0

      loop do
        opts[:locking_name] = self.class.send(locking_name_generator, self, opts)
        return if lock!(opts)

        opts[:attempt] += 1
        delay = self.class.send(backoff_algorithm, self, opts)

        raise Errors::DocumentCouldNotGetLock.new(self.class, id) if delay >= maximum_backoff || opts[:attempt] >= opts[:retries]

        sleep delay
      end
    end

    def lock!(opts)
      result = Mongoid::Locker::Wrapper.find_and_lock(self, opts)

      if result
        if opts[:reload]
          reload
        else
          self[locking_name_field] = result[locking_name_field.to_s]
          self[locked_at_field] = result[locked_at_field.to_s]
        end

        @has_lock = true
      else
        @has_lock = false
      end
    end

    def unlock!(opts)
      Mongoid::Locker::Wrapper.find_and_unlock(self, opts)

      unless destroyed?
        self[locking_name_field] = nil
        self[locked_at_field] = nil
      end

      @has_lock = false
    end
  end
end
