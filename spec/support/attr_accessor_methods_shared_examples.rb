# frozen_string_literal: true

RSpec.shared_examples 'attr_accessor methods' do
  module_methods = %i[
    locking_name_field
    locked_at_field
    maximum_backoff
    lock_timeout
    locker_write_concern
    backoff_algorithm
    locking_name_generator
  ]

  around(:example, :restore) do |example|
    method = example.metadata[:restore]
    defined_value = subject.instance_variable_get("@#{method}")

    example.run

    subject.instance_variable_set("@#{method}", defined_value)
  end

  module_methods.each do |method|
    describe "::#{method}" do
      let(:default_value) { send("default_#{method}") }

      it 'returns default value' do
        expect(subject.send(method)).to eq(default_value)
      end

      it 'returns assigned value', restore: method do
        subject.instance_variable_set("@#{method}", custom_field)
        expect(subject.send(method)).to eq(custom_field)
      end
    end

    describe "::#{method}=", restore: method do
      it 'sets value' do
        subject.send("#{method}=", custom_field)
        expect(subject.instance_variable_get("@#{method}")).to eq(custom_field)
      end
    end
  end
end
