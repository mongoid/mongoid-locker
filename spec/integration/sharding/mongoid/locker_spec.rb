# frozen_string_literal: true

RSpec.describe Mongoid::Locker, :sharding do
  before do
    skip 'Set SHARDED_MONGODB_URI to run sharding integration tests' unless ENV['SHARDED_MONGODB_URI']

    Mongoid.configure do |config|
      config.clients[:sharded] = { uri: ENV.fetch('SHARDED_MONGODB_URI') }
    end
    stub_const('ShardedLockDocument', Class.new do
      include Mongoid::Document
      include Mongoid::Locker

      store_in client: :sharded, collection: 'sharded_lock_documents'
      field :locking_name, type: String
      field :locked_at, type: Time
      field :value, type: Integer
    end)
    ShardedLockDocument.collection.drop
    client = ShardedLockDocument.mongo_client
    raise 'SHARDED_MONGODB_URI must connect to a mongos router' unless client.database.command(hello: 1).first['msg'] == 'isdbgrid'

    admin = client.use('admin')
    admin.database.command(enableSharding: client.database.name)
    ShardedLockDocument.collection.indexes.create_one(_id: shard_type)
    admin.database.command(shardCollection: "#{client.database.name}.sharded_lock_documents", key: { _id: shard_type })
  end

  after do
    ShardedLockDocument.collection.drop if defined?(ShardedLockDocument)
  end

  [1, 'hashed'].each do |type|
    context "with #{type.inspect} sharding" do
      let(:shard_type) { type }
      let(:document) { ShardedLockDocument.create!(value: 0) }

      it 'acquires a lock on a fresh document and releases it after saving' do
        document.with_lock(retries: 1) do
          expect(document).to have_lock
          expect(document.reload.locking_name).not_to be_nil
          document.update!(value: 1)
        end

        expect(document.reload.value).to eq(1)
        expect(document.locking_name).to be_nil
        expect(document.locked_at).to be_nil
      end

      it 'rejects contention without releasing the existing lock' do
        document.with_lock(retries: 1) do
          contender = ShardedLockDocument.find(document.id)
          expect { contender.with_lock(retries: 1) { raise 'must not acquire lock' } }
            .to raise_error(Mongoid::Locker::Errors::DocumentCouldNotGetLock)
          expect(document.reload.locking_name).not_to be_nil
        end
      end

      it 'takes over an expired lock without reloading' do
        document.set(locked_at: Time.now.utc - 60, locking_name: 'expired')
        document.with_lock(retries: 1, reload: false) do
          expect(document.locking_name).not_to eq('expired')
          expect(document.locked_at).to be > Time.now.utc - 10
        end
        expect(document.reload.locking_name).to be_nil
      end

      it 'releases the lock when the block raises' do
        expect { document.with_lock(retries: 1) { raise 'failure' } }.to raise_error(RuntimeError, 'failure')
        expect(document.reload.locking_name).to be_nil
        expect(document.locked_at).to be_nil
      end
    end
  end
end
