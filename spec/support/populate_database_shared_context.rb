# frozen_string_literal: true

RSpec.shared_context 'clear database' do
  after do |example|
    unless example.metadata[:delete_all] == false
      model.delete_all
      example.metadata[:delete_all] = false
    end
  end
end

RSpec.shared_context 'create document', :document do
  let!(:document) { model.create! }
  let(:dup_document) { model.find(document.id) }

  include_context 'clear database'
end

RSpec.shared_context 'create locked document', :locked do
  let!(:locked) do
    future_time = (t = Time.now) + t.to_i
    model.create!(
      model.locking_name_field => 'locked_name',
      model.locked_at_field => future_time
    )
  end

  include_context 'clear database'
end

RSpec.shared_context 'create unlocked document', :unlocked do
  let!(:unlocked) do
    past_time = Time.at(0)
    model.create!(
      model.locking_name_field => 'unlocked_name',
      model.locked_at_field => past_time
    )
  end

  include_context 'clear database'
end

RSpec.shared_context 'populate database', :populate do
  include_context 'create document'
  include_context 'create locked document'
  include_context 'create unlocked document'
end
