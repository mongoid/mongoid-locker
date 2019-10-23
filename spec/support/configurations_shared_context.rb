# frozen_string_literal: true

RSpec.shared_context 'default configuration' do
  before(:context) do
    Mongoid::Locker.reset!

    class User
      include Mongoid::Document
      include Mongoid::Locker

      field :locking_name, type: String
      field :locked_at, type: Time

      field :age, type: Integer

      index({ _id: 1, locking_name: 1 }, name: 'mongoid_locker_index', sparse: true, unique: true, expire_after_seconds: lock_timeout)
    end

    User.create_indexes
  end

  after(:context) do
    remove_models User
  end

  let(:model) { User }
end

RSpec.shared_context 'global configuration' do
  let(:default_locking_name_field) { :global_locking_name }
  let(:default_locked_at_field) { :global_locked_at }
  let(:default_lock_timeout) { 4 }
  let(:default_locker_write_concern) { { w: 1 } }
  let(:default_maximum_backoff) { 40.0 }
  let(:default_backoff_algorithm) { :custom_backoff }
  let(:default_locking_name_generator) { :secure_locking_name }
  let(:custom_field) { :global_custom_field }

  before(:context) do
    Mongoid::Locker.configure do |config|
      config.locking_name_field     = :global_locking_name
      config.locked_at_field        = :global_locked_at
      config.lock_timeout           =  4
      config.locker_write_concern   =  { w: 1 }
      config.maximum_backoff        = 40.0
      config.backoff_algorithm      = :custom_backoff
      config.locking_name_generator = :secure_locking_name
    end

    module Mongoid
      module Locker
        def self.custom_backoff(_doc, _opts)
          rand
        end
      end
    end

    class User
      include Mongoid::Document
      include Mongoid::Locker

      field :global_locking_name, type: String
      field :global_locked_at, type: Time

      field :age, type: Integer
    end
  end

  after(:context) do
    remove_models User
  end

  let(:model) { User }
end

RSpec.shared_context 'locker configuration' do
  let(:default_locking_name_field) { :locker_locking_name }
  let(:default_locked_at_field) { :locker_locked_at }
  let(:default_lock_timeout) { 3 }
  let(:default_locker_write_concern) { { w: 1 } }
  let(:default_maximum_backoff) { 30.0 }
  let(:default_backoff_algorithm) { :locked_at_backoff }
  let(:default_locking_name_generator) { :custom_locking_name }
  let(:custom_field) { :locker_custom_field }

  before(:context) do
    class User
      include Mongoid::Document
      include Mongoid::Locker

      locker locking_name_field: :locker_locking_name,
             locked_at_field: :locker_locked_at,
             lock_timeout: 3,
             locker_write_concern: { w: 1 },
             maximum_backoff: 30.0,
             backoff_algorithm: :locked_at_backoff,
             locking_name_generator: :custom_locking_name

      field :locker_locking_name, type: String
      field :locker_locked_at, type: Time

      field :age, type: Integer

      def self.custom_locking_name(_doc, _opts)
        SecureRandom.uuid
      end
    end
  end

  after(:context) do
    remove_models User
  end

  let(:model) { User }
end
