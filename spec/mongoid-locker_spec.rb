# frozen_string_literal: true

RSpec.describe Mongoid::Locker do
  let(:default_locking_name_field) { :locking_name }
  let(:default_locked_at_field) { :locked_at }
  let(:default_locker_write_concern) { { w: 1 } }
  let(:default_maximum_backoff) { 60.0 }
  let(:default_lock_timeout) { 5 }
  let(:default_backoff_algorithm) { :exponential_backoff }
  let(:default_locking_name_generator) { :secure_locking_name }
  let(:custom_field) { :custom_field }
  let(:parameters) do
    %i[
      locking_name_field
      locked_at_field
      maximum_backoff
      lock_timeout
      locker_write_concern
      backoff_algorithm
      locking_name_generator
    ]
  end
  let(:wrapper) { subject::Wrapper }

  it 'has a version number' do
    expect(Mongoid::Locker::VERSION).not_to be_nil
  end

  describe 'Mongoid::Locker::Errors' do
    include_examples 'locker errors'
  end

  describe 'Mongoid::Locker::Wrapper' do
    include_examples 'wrapper methods'
  end

  describe 'methods', :reset do
    include_examples 'locker methods'
  end

  describe 'usage scenarios' do
    context 'when set default configuration' do
      include_context 'default configuration'
      it_behaves_like 'Mongoid::Locker is included'
    end

    context 'when set global configuration' do
      include_context 'global configuration'
      it_behaves_like 'Mongoid::Locker is included'
    end

    context 'when set locker configuration' do
      include_context 'locker configuration'
      it_behaves_like 'Mongoid::Locker is included'
    end
  end
end
