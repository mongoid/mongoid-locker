# frozen_string_literal: true

RSpec.shared_examples 'delegated methods' do
  let(:document) { model.new }

  object_methods = %i[
    locking_name_field
    locked_at_field
    maximum_backoff
    lock_timeout
    locker_write_concern
    backoff_algorithm
    locking_name_generator
  ]

  object_methods.each do |method|
    describe "##{method}" do
      it 'is delegated to the class' do
        expect(model).to receive(method)
        document.send(method)
      end
    end
  end

  class_methods = %i[
    secure_locking_name
    exponential_backoff
    locked_at_backoff
  ]

  class_methods.each do |method|
    describe "::#{method}" do
      it 'is delegated to the Mongoid::Locker' do
        expect(subject).to receive(method)
        model.send(method, {}, {})
      end
    end
  end
end
