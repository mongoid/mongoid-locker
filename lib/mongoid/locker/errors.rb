module Mongoid
  module Locker
    module Errors
      # Raised when a document could not be successfully locked in the database.
      class DocumentCouldNotGetLock < StandardError
        BASE_KEY = 'mongoid.locker.errors.messages'.freeze

        # @example Create new error.
        #   DocumentCouldNotGetLock.new(Account, '1234')
        #
        # @param klass [Class] the model class
        # @param id [String, BSON::ObjectId] the document's id
        def initialize(klass, id)
          message = I18n.translate("#{BASE_KEY}.#{key}.message", klass: klass, id: id.to_s)

          super("\nmessage:\n  #{message}")
        end

        private

        def key
          'document_could_not_get_lock'
        end
      end
    end
  end
end
