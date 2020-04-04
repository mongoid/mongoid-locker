# frozen_string_literal: true

RSpec.shared_examples 'Mongoid::Locker is included' do
  include_examples 'delegated methods'
  it_behaves_like 'attr_accessor methods' do
    subject { model }
  end

  describe '::secure_locking_name' do
    let(:document) { model.new }

    it 'uses SecureRandom.urlsafe_base64 by default' do
      expect(SecureRandom).to receive(:urlsafe_base64).once.and_return('name')
      expect(model.secure_locking_name(document, attempt: 0)).to match('name#0')
    end

    it 'returns string' do
      expect(model.secure_locking_name(document, attempt: 0)).to be_a(String)
    end
  end

  describe '::exponential_backoff' do
    let(:document) { model.new }

    it 'increases delay with each attempt' do
      first_delay = model.exponential_backoff(document, attempt: 0)
      next_delay = model.exponential_backoff(document, attempt: 1)

      expect(first_delay).to be < next_delay
    end

    it 'returns number' do
      delay = model.exponential_backoff(document, attempt: 0)
      expect(delay).to be_a(Float).or be_a(Integer)
    end
  end

  describe '::locked_at_backoff' do
    let(:document) { model.new }
    let(:locked_at) { Time.now }

    it 'does not request locked_at and current_mongodb_time when it is reached a limit' do
      allow(wrapper).to receive(:locked_at).exactly(0)
      allow(wrapper).to receive(:current_mongodb_time).exactly(0)

      opts = {}
      opts[:attempt] = default_maximum_backoff / default_lock_timeout
      expect(model.locked_at_backoff(document, opts)).to eq(default_maximum_backoff)
    end

    it 'returns 0 when locked_at is nil' do
      allow(wrapper).to receive(:locked_at).and_return(nil)
      allow(wrapper).to receive(:current_mongodb_time).exactly(0)

      expect(model.locked_at_backoff(document, attempt: 0)).to be_zero
    end

    it 'returns 0 when the time of lock is elapsed' do
      mongodb_time = locked_at + 1 + document.lock_timeout
      allow(wrapper).to receive(:locked_at).exactly(1).and_return(locked_at)
      allow(wrapper).to receive(:current_mongodb_time).exactly(1).and_return(mongodb_time)

      expect(model.locked_at_backoff(document, attempt: 0)).to be_zero
    end

    it 'returns the time until the lock is out' do
      mongodb_time = locked_at + 1
      delay = document.lock_timeout - 1
      allow(wrapper).to receive(:locked_at).exactly(1).and_return(locked_at)
      allow(wrapper).to receive(:current_mongodb_time).exactly(1).and_return(mongodb_time)

      expect(model.locked_at_backoff(document, attempt: 0)).to be_within(1.01).of(delay)
    end
  end

  describe '::locker' do
    let(:locker_field) { :locker_field }
    let(:param_error) { Mongoid::Locker::Errors::InvalidParameter }

    around(:example, :restore) do |example|
      values = Hash[parameters.map { |param| [param, model.send(param)] }]

      example.run

      values.each_pair { |k, v| model.send("#{k}=", v) }
    end

    it 'configures parameters of the model', :restore do
      model.class_exec(self) do |context|
        locker lock_timeout: context.locker_field,
               locking_name_field: context.locker_field,
               locked_at_field: context.locker_field,
               locker_write_concern: context.locker_field,
               maximum_backoff: context.locker_field,
               backoff_algorithm: context.locker_field,
               locking_name_generator: context.locker_field
      end

      attributes = Hash[parameters.map { |param| [param, locker_field] }]
      expect(model).to have_attributes(**attributes)
    end

    it 'raises error for undefined parameter' do
      expect { model.locker(bad_param: :bad_field) }.to raise_error(param_error)
    end
  end

  describe '::locked' do
    it 'returns Mongoid::Criteria' do
      expect(model.locked).to be_a(Mongoid::Criteria)
    end

    it 'is chainable' do
      criteria = model.where(_id: 1).locked.where(_id: 2)
      expect(criteria).to be_a(Mongoid::Criteria)
    end

    it 'selects locked document', :populate do
      expect(model.locked.count).to eq(1)
    end
  end

  describe '::unlocked' do
    it 'returns Mongoid::Criteria' do
      expect(model.unlocked).to be_a(Mongoid::Criteria)
    end

    it 'is chainable' do
      expect do
        criteria = model.where(_id: 1).unlocked.where(_id: 2)
        expect(criteria.selector['_id']).to eq(2)
      end.not_to raise_error
    end

    it 'selects unlocked documents', :populate do
      expect(model.unlocked.count).to eq(2)
    end
  end

  describe '::unlock_all' do
    it 'returns number of unlocked documents' do
      expect(model.unlock_all).to eq(0)
    end

    it 'unlocks locked documents', :populate do
      locked = model.locked.count

      expect(model.locked.unlock_all).to eq(locked)
      expect(model.locked.unlock_all).to eq(0)
    end
  end

  describe '#locked?' do
    context 'when the document is not persisted' do
      let(:document) { model.new }

      it 'is not locked' do
        expect(document).not_to be_locked
      end

      it 'does not hit the database' do
        expect(model).not_to receive(:locked)
        document.locked?
      end
    end

    context 'when the document is created', :document do
      it 'is not locked' do
        expect(document).not_to be_locked
      end

      it 'hits the database' do
        expect(model).to receive(:locked).once.and_call_original
        document.locked?
      end
    end

    context 'when the document has #with_lock', :document do
      it 'is true' do
        document.with_lock do
          expect(document).to be_locked
        end
      end

      it 'is true on another instance' do
        document.with_lock do
          expect(dup_document).to be_locked
        end
      end
    end

    context 'when the document is retrieved from the database' do
      it 'is true when locked', :locked do
        expect(locked).to be_locked
      end

      it 'is false when unlocked', :unlocked do
        expect(unlocked).not_to be_locked
      end
    end
  end

  describe '#has_lock?' do
    it 'is not has_lock when it is not persisted' do
      expect(model.new).not_to have_lock
    end

    it 'is not has_lock when created', :document do
      expect(document).not_to have_lock
    end

    it 'is true when it has #with_lock', :document do
      document.with_lock do
        expect(document).to have_lock
      end
    end

    it 'is false after it had #with_lock', :document do
      document.with_lock {}
      expect(document).not_to have_lock
    end

    it 'is true when it is recursive lock', :document do
      document.with_lock do
        document.with_lock do
          expect(document).to have_lock
        end
      end
    end
  end

  describe '#with_lock' do
    let(:lock_error) { Mongoid::Locker::Errors::DocumentCouldNotGetLock }

    context 'when document is not persisted' do
      let(:document) { model.new }

      it 'is not locked and has not has_lock' do
        document.with_lock do
          expect(document).not_to be_locked
          expect(document).not_to have_lock
        end
      end

      it 'does not try to hit the database' do
        expect(wrapper).not_to receive(:find_and_lock)
        expect(wrapper).not_to receive(:find_and_unlock)

        document.with_lock {}
      end

      it 'does not fail' do
        expect do
          document.with_lock {}
        end.not_to raise_error
      end
    end

    it 'locks and unlocks the document', :document do
      document.with_lock do
        expect(document).to be_locked.and have_lock
      end

      expect(document).not_to be_locked
      expect(document).not_to have_lock
    end

    it 'does not save the document into the database', :document do
      expect do
        document.with_lock do
          document.age = 10
        end

        document.reload
      end.not_to change(document, :age)
    end

    it 'handles errors gracefully', :document do
      expect do
        document.with_lock do
          raise 'error'
        end
      end.to raise_error('error')

      expect(document).not_to be_locked
      expect(document).not_to have_lock
    end

    it 'raises error if trying to lock locked document', :locked, :no_backoff do
      expect do
        locked.with_lock {}
      end.to raise_error(lock_error)
    end

    it 'handles recursive calls', :document do
      expect do
        document.with_lock do
          document.with_lock do
            document.age = 10
          end
        end
      end.to change(document, :age)
    end

    it 'only hits the database twice for lock and unlock', :document do
      expect(wrapper).to receive(:find_and_lock).once.and_call_original
      expect(wrapper).to receive(:find_and_unlock).once.and_call_original

      document.with_lock {}
    end

    it 'only hits the database twice for lock and unlock for recursive calls', :document do
      expect(wrapper).to receive(:find_and_lock).once.and_call_original
      expect(wrapper).to receive(:find_and_unlock).once.and_call_original

      document.with_lock do
        document.with_lock {}
      end
    end

    it 'gets lock when time of lock is out', :document, :no_timeout do
      expect do
        document.with_lock do
          dup_document.with_lock do
            dup_document.age = 10
            dup_document.save!
          end
        end

        document.reload
      end.to change(document, :age)
    end

    it 'does not fail if the lock has been released between checks', :document, :no_delay do
      allow(wrapper).to receive(:find_and_lock).and_return(nil, {})
      document.with_lock(retries: 2) {}
    end

    it 'by default, reloads the document after acquiring the lock', :document do
      allow(document).to receive(:reload).once.and_call_original

      document.with_lock do
        expect(document).to have_attributes(
          model.locking_name_field => be,
          model.locked_at_field => be
        )
      end
    end

    it 'allows override of the default reload behavior', :document do
      expect(document).not_to receive(:reload)

      document.with_lock reload: false do
        expect(document).to have_attributes(
          model.locking_name_field => be,
          model.locked_at_field => be
        )
      end
    end

    it 'tries the exact number of :retries option', :locked, :no_delay do
      allow(wrapper).to receive(:find_and_lock).and_return(nil, {})
      locked.with_lock(retries: 2) {}
    end
  end
end
