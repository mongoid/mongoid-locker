RSpec.shared_examples 'wrapper methods' do
  include_context 'default configuration'

  describe '::find_and_lock' do
    it 'locks and returns locking_name_field and locked_at_field values', :document do
      opts = { locking_field: document[model.locking_name_field] }
      result = wrapper.find_and_lock(document, opts)

      expect(result).to match(
        model.locking_name_field.to_s => eq(opts[:locking_name]),
        model.locked_at_field.to_s => be_a(Time)
      )
    end

    it 'does not lock locked document', :locked do
      opts = { locking_field: locked[model.locking_name_field] }
      expect(wrapper.find_and_lock(locked, opts)).to be_nil
    end

    it 'locks locked document if lock time is elapsed', :unlocked do
      opts = { locking_field: unlocked[model.locking_name_field] }
      result = wrapper.find_and_lock(unlocked, opts)

      expect(result[model.locking_name_field.to_s]).to eq(opts[:locking_name])
    end
  end

  describe '::find_and_unlock' do
    it 'unlocks locked document', :locked do
      expect(wrapper.find_and_unlock(locked)).to be_truthy

      locked.reload
      expect(locked).to have_attributes(
        model.locking_name_field => be_nil,
        model.locked_at_field => be_nil
      )
    end

    it 'returns false if unlocked document was found', :document do
      expect(wrapper.find_and_unlock(document)).to be_falsy
    end

    it 'returns false if the document it not found' do
      expect(wrapper.find_and_unlock(model.new)).to be_falsy
    end
  end

  describe '::locked_at' do
    it 'returns locked_at_field time', :locked do
      time = locked[model.locked_at_field]
      locked_at = wrapper.locked_at(locked)

      expect(locked_at).to be_a(Time).and be_within(0.02).of(time)
    end

    it 'returns nil if locked_at_field is nil', :document do
      expect(wrapper.locked_at(document)).to be_nil
    end

    it 'returns nil if the document is not persisted' do
      document = model.new
      expect(wrapper.locked_at(document)).to be_nil
    end
  end

  describe '::current_mongodb_time' do
    it 'returns time' do
      expect(wrapper.current_mongodb_time(model)).to be_a(Time)
    end
  end
end
