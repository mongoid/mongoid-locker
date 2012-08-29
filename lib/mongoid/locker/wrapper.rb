module Mongoid
  module Locker
    # Normalizes queries between Mongoid 2 and 3.
    module Wrapper
      IS_OLD_MONGOID = Mongoid::VERSION.start_with? '2.'

      # Update the document for the provided Class matching the provided query with the provided setter.
      #
      # @param [Class] The model class
      # @param [Hash] The Mongoid query
      # @param [Hash] The Mongoid setter
      # @return [Boolean] true if the document was successfully updated, false otherwise
      def self.update klass, query, setter
        error_obj =
          if IS_OLD_MONGOID
            klass.collection.update(query, setter, :safe => true)
          else
            klass.with(:safe => true).collection.find(query).update(setter)
          end

        error_obj['n'] == 1
      end

      # Determine whether the provided document is locked in the database or not.
      #
      # @param [Class] The model instance
      # @return [Time] The timestamp of when the document is locked until, nil if not locked.
      def self.locked_until doc
        existing_query = {
          :_id => doc.id,
          :locked_until => {'$exists' => true}
        }

        if IS_OLD_MONGOID
          existing = doc.class.collection.find_one(existing_query, :fields => {:locked_until => 1})
          existing ? existing['locked_until'] : nil
        else
          existing = doc.class.where(existing_query).limit(1).only(:locked_until).first
          existing ? existing.locked_until : nil
        end
      end
    end
  end
end
