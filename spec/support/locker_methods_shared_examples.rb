# frozen_string_literal: true

RSpec.shared_examples 'locker methods' do
  include_examples 'attr_accessor methods'

  describe '::configure' do
    it 'configures all parameters' do
      subject.configure do |config|
        parameters.each { |param| config.send("#{param}=", custom_field) }
      end

      attributes = Hash[parameters.map { |param| [param, custom_field] }]
      expect(subject).to have_attributes(**attributes)
    end
  end

  describe '::reset!' do
    it 'resets to default parameters' do
      parameters.each { |param| subject.send("#{param}=", custom_field) }

      subject.reset!

      attributes = Hash[parameters.map { |param| [param, send("default_#{param}")] }]
      expect(subject).to have_attributes(**attributes)
    end
  end
end
