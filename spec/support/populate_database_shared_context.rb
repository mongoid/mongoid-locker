# frozen_string_literal: true

RSpec.shared_context 'with database cleared' do
  after do |example|
    unless example.metadata[:delete_all] == false
      model.delete_all
      example.metadata[:delete_all] = false
    end
  end
end

RSpec.shared_context 'with a document', :document do
  let!(:document) { model.create! }
  let(:dup_document) { model.find(document.id) }

  include_context 'with database cleared'
end

RSpec.shared_context 'with a locked document', :locked do
  let!(:locked) do
    future_time = (t = Time.now) + t.to_i
    model.create!(
      model.locking_name_field => 'locked_name',
      model.locked_at_field => future_time
    )
  end

  include_context 'with database cleared'
end

RSpec.shared_context 'with an unlocked document', :unlocked do
  let!(:unlocked) do
    past_time = Time.at(0)
    model.create!(
      model.locking_name_field => 'unlocked_name',
      model.locked_at_field => past_time
    )
  end

  include_context 'with database cleared'
end

RSpec.shared_context 'with a populated database', :populate do
  include_context 'with a document'
  include_context 'with a locked document'
  include_context 'with an unlocked document'
end
