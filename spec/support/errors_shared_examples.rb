# frozen_string_literal: true

RSpec.shared_examples 'locker errors' do
  let(:base_key) { 'mongoid.locker.errors.messages' }
  let(:klass) { subject }

  describe 'DocumentCouldNotGetLock' do
    let(:error) { Mongoid::Locker::Errors::DocumentCouldNotGetLock }
    let(:key) { "#{base_key}.document_could_not_get_lock.message" }
    let(:id) { BSON::ObjectId.new }
    let(:message) { I18n.translate(key, klass: klass, id: id) }

    it 'returns the error with message' do
      expect do
        raise error.new(klass, id)
      end.to raise_error(error, include(message))
    end
  end

  describe 'InvalidParameter' do
    let(:error) { Mongoid::Locker::Errors::InvalidParameter }
    let(:key) { "#{base_key}.invalid_parameter.message" }
    let(:parameter) { :invalid_parameter }
    let(:message) { I18n.translate(key, klass: klass, parameter: parameter) }

    it 'returns the error with message' do
      expect do
        raise error.new(klass, parameter)
      end.to raise_error(error, include(message))
    end
  end
end
