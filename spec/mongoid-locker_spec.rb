require File.join(File.dirname(__FILE__), 'spec_helper')

describe Mongoid::Locker do
  before do
    # recreate the class for each spec
    class User
      include Mongoid::Document
      include Mongoid::Locker

      field :account_balance, type: Float
    end
  end

  after { Object.send :remove_const, :User }

  it "should find no users to start" do
    User.all.should be_empty
  end
end
