RSpec.shared_examples 'locker errors' do
  describe 'DocumentCouldNotGetLock' do
    let(:error) { Mongoid::Locker::Errors::DocumentCouldNotGetLock }
    let(:key) { 'mongoid.locker.errors.messages.document_could_not_get_lock.message' }
    let(:id) { BSON::ObjectId.new }
    let(:klass) { subject }
    let(:message) { I18n.translate(key, klass: klass, id: id) }

    it 'returns the error with message' do
      expect do
        raise error.new(klass, id)
      end.to raise_error(error, include(message))
    end
  end
end
