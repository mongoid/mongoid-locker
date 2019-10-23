# frozen_string_literal: true

RSpec.shared_examples 'wrapper methods' do
  include_context 'default configuration'

  describe '::find_and_lock' do
    let(:opts) { { locking_name: 'locked' } }

    it 'locks and returns locking_name_field and locked_at_field values', :document do
      result = wrapper.find_and_lock(document, opts)

      expect(result).to match(
        model.locking_name_field.to_s => eq(opts[:locking_name]),
        model.locked_at_field.to_s => be_a(Time)
      )
    end

    it 'does not lock locked document', :locked do
      result = wrapper.find_and_lock(locked, opts)
      expect(result).to be_nil
    end

    it 'locks locked document if lock time is elapsed', :unlocked do
      result = wrapper.find_and_lock(unlocked, opts)
      locking_name = result[model.locking_name_field.to_s]

      expect(locking_name).to eq(opts[:locking_name])
    end
  end

  describe '::find_and_unlock', :locked do
    it 'unlocks locked document' do
      opts = { locking_name: locked[model.locking_name_field] }
      expect(wrapper.find_and_unlock(locked, opts)).to be_truthy
    end

    it 'returns false if locked document was not found' do
      expect(wrapper.find_and_unlock(model.new, {})).to be_falsy
    end

    it 'tolerates to empty locking_name_field' do
      opts = { locking_name: locked[model.locking_name_field] }
      locked[model.locking_name_field] = nil

      expect(wrapper.find_and_unlock(locked, opts)).to be_truthy
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
