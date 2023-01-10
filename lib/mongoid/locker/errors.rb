# frozen_string_literal: true

module Mongoid
  module Locker
    module Errors
      # Default parent Mongoid::Locker error for all custom errors.
      class MongoidLockerError < StandardError
        BASE_KEY = 'mongoid.locker.errors.messages'

        def initialize(key, **params)
          message = I18n.translate("#{BASE_KEY}.#{key}.message", **params)

          super("\nmessage:\n  #{message}")
        end
      end

      # Raised when a document could not be successfully locked in the database.
      class DocumentCouldNotGetLock < MongoidLockerError
        KEY = 'document_could_not_get_lock'

        # @example Create new error.
        #   DocumentCouldNotGetLock.new(Account, '1234')
        #
        # @param klass [Class] the model class
        # @param id [String, BSON::ObjectId] the document's id
        def initialize(klass, id)
          super(KEY, klass: klass, id: id.to_s)
        end
      end

      # Raised when trying to pass an invalid parameter to locker method by a class.
      class InvalidParameter < MongoidLockerError
        KEY = 'invalid_parameter'

        # @example Create new error.
        #   InvalidParameter.new(User, :lock_timeout)
        #
        # @param klass [Class] the model class
        # @param parameter [String, Symbol] the class parameter
        def initialize(klass, parameter)
          super(KEY, klass: klass, parameter: parameter)
        end
      end
    end
  end
end
