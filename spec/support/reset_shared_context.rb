# frozen_string_literal: true

RSpec.shared_context 'reset module parameters', :reset do
  before do
    Mongoid::Locker.reset!
  end
end

RSpec.shared_context 'set maximum_backoff to 0', :no_backoff do
  before do
    allow(model).to receive(:maximum_backoff).and_return(0)
  end
end

RSpec.shared_context 'set lock_timeout to 0', :no_timeout do
  before do
    allow(model).to receive(:lock_timeout).and_return(0)
  end
end

RSpec.shared_context 'backoff_algorithm returns 0', :no_delay do
  before do
    allow(model).to receive(model.backoff_algorithm).and_return(0)
  end
end
