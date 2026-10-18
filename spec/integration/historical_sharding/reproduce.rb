# frozen_string_literal: true

require 'mongoid'
require 'mongoid-locker'
require 'json'

Mongoid.configure do |config|
  config.sessions = {
    default: { hosts: ['localhost:27017'], database: 'locker_2013', options: { safe: true } }
  }
end

session = Mongoid.default_session
raise 'Expected mongos' unless session.command(ismaster: 1)['msg'] == 'isdbgrid'

admin = Moped::Session.new(['localhost:27017'])
admin.use('admin')
raise 'Expected two shards' unless admin.command(listShards: 1)['shards'].size == 2

puts "Ruby #{RUBY_VERSION}p#{RUBY_PATCHLEVEL}"
puts "MongoDB #{session.command(buildinfo: 1)['version']}"
puts(Gem.loaded_specs.values.select { |spec| %w[mongoid-locker mongoid moped].include?(spec.name) }
        .map { |spec| "#{spec.name} #{spec.version}" })

failures = []
%w[unsharded ranged hashed tenant].each do |collection|
  model = Class.new do
    include Mongoid::Document
    include Mongoid::Locker

    field :tenant, type: String
    field :value, type: Integer
    store_in collection: collection
  end
  Object.const_set("Historical#{collection.capitalize}", model)
  ids = 16.times.map do |index|
    id = Moped::BSON::ObjectId.from_string(format('%024x', (index * (2**92)) + 1))
    document = model.new(tenant: index.even? ? 'alpha' : 'zulu', value: 0)
    # Mongoid 3.1 ignores _id in mass assignment.
    document.id = id
    document.save!
    id
  end

  # Check physical placement, not just sharding metadata.
  counts = [27_018, 27_020].map do |port|
    shard = Moped::Session.new(["localhost:#{port}"])
    shard.use('locker_2013')
    shard[collection].find.count
  end
  raise "Expected 16 stored documents: #{counts.inspect}" unless counts.inject(:+) == 16
  raise "Expected data on both shards for #{collection}: #{counts.inspect}" if collection != 'unsharded' && counts.any? { |count| count == 0 }

  puts JSON.generate(collection: collection, shard_counts: counts)
  raise 'Router cannot read all inserted documents' unless model.collection.find.to_a.map { |row| row['_id'].to_s }.sort == ids.map(&:to_s).sort

  first_document = model.first
  acquired = 0
  ids.each do |id|
    # Include the report's Item.first path as well as explicit ID lookups.
    document = id == first_document.id ? first_document : model.find(id)
    raise 'Expected a fresh unlocked document' unless document.locked_at.nil? && document.locked_until.nil?

    begin
      document.with_lock do
        raise 'Lock not held' unless document.has_lock?

        stored = model.collection.find(_id: id).first
        raise 'Lock not persisted' unless stored['locked_at'] && stored['locked_until'] > Time.now

        document.update_attributes!(value: 1)
      end
      raise 'Update not persisted' unless document.reload.value == 1
      raise 'Lock not released' if document.has_lock?
      raise 'Lock fields not cleared in storage' unless document.locked_at.nil? && document.locked_until.nil?

      acquired += 1
    rescue Mongoid::Locker::LockError => e
      failures << [collection, document.id.to_s, e.message]
      puts JSON.generate(collection: collection, outcome: e.class.name, message: e.message,
                         stored: model.collection.find(_id: document.id).first)
    end
  end
  raise 'Not all documents were attempted' unless acquired + failures.count { |failure| failure.first == collection } == 16
  raise 'Unexpected persisted update count' unless model.where(value: 1).count == acquired

  puts JSON.generate(collection: collection, acquired: acquired, attempted: 16)
end

raise "Lock failures: #{failures.inspect}" unless failures.empty?

puts 'No reproduction: all 64 fresh documents acquired and released their locks.'
