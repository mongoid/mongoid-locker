# frozen_string_literal: true

RSpec.shared_context 'with reset module parameters', :reset do
  before do
    Mongoid::Locker.reset!
  end
end

RSpec.shared_context 'with maximum_backoff set to 0', :no_backoff do
  before do
    allow(model).to receive(:maximum_backoff).and_return(0)
  end
end

RSpec.shared_context 'with lock_timeout set to 0', :no_timeout do
  before do
    allow(model).to receive(:lock_timeout).and_return(0)
  end
end

RSpec.shared_context 'when backoff_algorithm returns 0', :no_delay do
  before do
    allow(model).to receive(model.backoff_algorithm).and_return(0)
  end
end
