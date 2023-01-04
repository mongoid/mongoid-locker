# frozen_string_literal: true

RSpec.describe 'Test examples' do
  before(:all) do
    Mongoid::Locker.reset!

    class Customer
      include Mongoid::Document
      include Mongoid::Locker

      field :locking_name, type: String
      field :locked_at, type: Time

      field :amount, type: Integer
    end

    class CustomerService
      attr_reader :customer

      def initialize(customer)
        @customer = customer
      end

      def add_amount!(amount)
        customer.with_lock do
          customer.update!(amount: customer.amount + amount)
        end
      rescue Mongoid::Locker::Errors::DocumentCouldNotGetLock
        # document was locked
      end
    end
  end

  after(:all) do
    remove_models Customer
  end

  let(:document) { Customer.create!(amount: 10) }
  let(:customer) { Customer.find(document.to_param) }

  context 'when the document is already locking' do
    before do
      # create document
      document

      # lock the document
      Mongoid::Locker::Wrapper.find_and_lock(document, locking_name: 'any_name')

      # or call model method to generate unique name for the lock
      # locking_name = Customer.secure_locking_name(nil, attempt: 0)
      # Mongoid::Locker::Wrapper.find_and_lock(document, locking_name: locking_name)
    end

    it 'does not add amount to customer 1' do
      # no delay between attempts to lock the customer (by default 5 attempts will be made until lock timeout is elapsed)
      allow(Customer).to receive(:maximum_backoff).and_return(0)

      expect do
        CustomerService.new(customer).add_amount!(7)
      end.not_to change(customer.reload, :amount)
    end

    it 'does not add amount to customer 2' do
      # only one attempt to lock the customer until lock timeout is elapsed
      allow(customer).to receive(:with_lock).and_wrap_original do |original|
        # document.with_lock(retries: 1)
        original.call(retries: 1)
      end

      expect do
        CustomerService.new(customer).add_amount!(7)
      end.not_to change(customer.reload, :amount)
    end
  end
end
