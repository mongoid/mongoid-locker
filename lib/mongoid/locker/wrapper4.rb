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
        klass.with(safe: true).collection.find(query).update(setter)['n'] == 1
      end

      def self.locked_until(doc)
        existing_query = { _id: doc.id, doc.locked_until_field => { '$exists' => true } }
        existing = doc.class.where(existing_query).limit(1).only(doc.locked_until_field).first
        existing ? existing[doc.locked_until_field] : nil
      end
    end
  end
end
