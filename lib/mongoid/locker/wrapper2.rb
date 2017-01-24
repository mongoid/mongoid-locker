module Mongoid
  module Locker
    # Normalizes queries between various Mongoid versions.
    module Wrapper
      # Update the document for the provided Class matching the provided query with the provided setter.
      #
      # @param [Class] The model class
      # @param [Hash] The Mongoid query
      # @param [Hash] The Mongoid setter
      # @return [Boolean] true if the document was successfully updated, false otherwise
      def self.update(klass, query, setter)
        klass.collection.update(query, setter, safe: true)['n'] == 1
      end

      # Determine whether the provided document is locked in the database or not.
      #
      # @param [Class] The model instance
      # @return [Time] The timestamp of when the document is locked until, nil if not locked.
      def self.locked_until(doc)
        existing_query = { _id: doc.id, mongoid_locker_locked_until: { '$exists' => true } }
        existing = doc.class.collection.find_one(existing_query, fields: { mongoid_locker_locked_until: 1 })
        existing ? existing['mongoid_locker_locked_until'] : nil
      end
    end
  end
end
