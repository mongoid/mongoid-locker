# frozen_string_literal: true

RSpec.describe Mongoid::Locker do
  before do
    stub_const('EmbeddedLockChild', Class.new do
      include Mongoid::Document

      field :status, type: Integer
      embedded_in :parent, class_name: 'EmbeddedLockParent', inverse_of: :children
    end)
    stub_const('EmbeddedLockParent', Class.new do
      include Mongoid::Document
      include Mongoid::Locker

      store_in collection: 'embedded_lock_parents'
      field :locking_name, type: String
      field :locked_at, type: Time
      field :option, type: Integer
      embeds_many :children, class_name: 'EmbeddedLockChild', inverse_of: :parent
    end)
  end

  after do
    EmbeddedLockParent.delete_all
  end

  let(:parent) { EmbeddedLockParent.create!(option: 0, children: [EmbeddedLockChild.new(status: 0)]) }

  it 'persists embedded changes when the child is retrieved after locking' do
    parent.with_lock do
      child = parent.children.first
      child.status = 2
      parent.option = 4
      parent.save!
    end

    expect(parent.reload.option).to eq(4)
    expect(parent.children.first.status).to eq(2)
    expect(parent.locking_name).to be_nil
  end

  it 'reproduces stale child references when the parent is reloaded on acquisition' do
    child = parent.children.first

    parent.with_lock do
      expect(parent.children.first).not_to equal(child)
      child.status = 2
      parent.option = 4
      parent.save!
    end

    expect(parent.reload.option).to eq(4)
    expect(parent.children.first.status).to eq(0)
  end

  it 'allows a child selected before locking to be retrieved again by id' do
    child_id = parent.children.first.id

    parent.with_lock do
      parent.children.find(child_id).status = 2
      parent.save!
    end

    expect(parent.reload.children.first.status).to eq(2)
  end

  it 'preserves existing embedded references when reloading is disabled' do
    child = parent.children.first

    parent.with_lock(reload: false) do
      expect(parent.children.first).to equal(child)
      child.status = 2
      parent.option = 4
      parent.save!
    end

    expect(parent.reload.option).to eq(4)
    expect(parent.children.first.status).to eq(2)
    expect(parent.locking_name).to be_nil
  end
end
