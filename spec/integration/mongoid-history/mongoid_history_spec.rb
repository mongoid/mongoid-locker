# frozen_string_literal: true

require 'mongoid-history'

# This replicates the exception reported at https://github.com/mongoid/mongoid-history/issues/238#issuecomment-1063155193
# when mongoid-locker required 'forwardable' instead of relying on the
# active support-provided delegation method
RSpec.describe 'MongoidHistory' do # rubocop:disable RSpec/DescribeClass
  # rubocop:disable RSpec/ExampleLength
  it 'does not raise an exception' do
    expect do
      Class.new do
        include Mongoid::Document
        include Mongoid::Locker
        include Mongoid::History::Trackable

        field :title

        track_history on: [:title]
      end
    end.not_to raise_exception
  end
  # rubocop:enable RSpec/ExampleLength
end
