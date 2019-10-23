# frozen_string_literal: true

module Mongoid
  module Locker
    # Set of methods to interact with the database.
    module Wrapper
      # Finds provided document with provided options, locks (sets +locking_name_field+ and +locked_at_field+ fields), and returns the fields.
      #
      # @example
      #   Mongoid::Locker::Wrapper.find_and_lock(document, opts)
      #   #=> {"locked_at"=>2019-03-19 07:51:24 UTC, "locking_name"=>nil}
      #
      # @example
      #   Mongoid::Locker::Wrapper.find_and_lock(document, opts)
      #   # => nil
      #
      # @param doc [Mongoid::Document]
      # @param opts [Hash] (see #with_lock)
      # @return [Hash] with +locking_name_field+ and +locked_at_field+ fields
      # @return [nil] if the document was not found, was already locked
      def self.find_and_lock(doc, opts)
        model = doc.class
        filter = {
          _id: doc.id,
          '$or': [
            {
              '$or': [
                { model.locking_name_field => { '$exists': false } },
                { model.locked_at_field => { '$exists': false } }
              ]
            },
            {
              '$or': [
                { model.locking_name_field => { '$eq': nil } },
                { model.locked_at_field => { '$eq': nil } }
              ]
            },
            {
              '$where': "new Date() - this.#{model.locked_at_field} >= #{model.lock_timeout * 1000}"
            }
          ]
        }
        update = {
          '$set': { model.locking_name_field => opts[:locking_name] },
          '$currentDate': { model.locked_at_field => true }
        }
        options = {
          return_document: :after,
          projection: { _id: false, model.locking_name_field => true, model.locked_at_field => true },
          write_concern: model.locker_write_concern
        }

        model.collection.find_one_and_update(filter, update, options)
      end

      # Finds provided document with provided options, unlocks (sets +locking_name_field+ and +locked_at_field+ fields to +nil+).
      #
      # @example
      #   Mongoid::Locker::Wrapper.find_and_unlock(doc, opts)
      #   #=> true
      #   Mongoid::Locker::Wrapper.find_and_unlock(doc, opts)
      #   #=> false
      #
      # @param doc [Mongoid::Document]
      # @param opts [Hash] (see #with_lock)
      # @return [Boolean]
      # @return [true] if the document was unlocked
      # @return [false] if the document was not found, was not unlocked
      def self.find_and_unlock(doc, opts)
        model = doc.class
        filter = {
          _id: doc.id,
          model.locking_name_field => opts[:locking_name]
        }
        update = {
          '$set': {
            model.locking_name_field => nil,
            model.locked_at_field => nil
          }
        }
        options = { write_concern: model.locker_write_concern }

        result = model.collection.update_one(filter, update, options)
        result.ok? && result.written_count == 1
      end

      # Returns value of +locked_at_field+ field for provided document.
      #
      # @example
      #   Mongoid::Locker::Wrapper.locked_at(document)
      #   #=> 2019-06-03 13:50:46 UTC
      #
      # @param doc [Mongoid::Document]
      # @return [Time] +locked_at_field+ field time
      # @return [nil] if response was failed
      def self.locked_at(doc)
        result = doc.class.collection.find(
          { _id: doc.id },
          projection: { _id: false, doc.locked_at_field => true },
          limit: 1
        ).first

        result[doc.locked_at_field.to_s] if result
      end

      # Returns the local database server time in UTC.
      #
      # @example
      #   Mongoid::Locker::Wrapper.current_mongodb_time(User)
      #   #=> 2019-03-19 07:24:36 UTC
      #
      # @param model [Class] the model class
      # @return [Time] current time
      # @return [nil] if response was failed
      def self.current_mongodb_time(model)
        info = model.collection.database.command(isMaster: 1)
        info.ok? ? info.documents.first['localTime'] : nil
      end
    end
  end
end
