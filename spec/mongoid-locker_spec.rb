require File.join(File.dirname(__FILE__), 'spec_helper')

describe Mongoid::Locker do
  before do
    # recreate the class for each spec
    class User
      include Mongoid::Document
      include Mongoid::Locker

      field :account_balance, type: Integer # easier to test than Float
    end
  end

  after do
    User.delete_all
    Object.send :remove_const, :User
  end

  it "should find no users to start" do
    User.all.should be_empty
  end

  it "shouldn't be locked when created" do
    user = User.create!
    user.should_not be_locked
    User.first.should_not be_locked
  end

  describe "#with_lock" do
    it "should lock and unlock the user" do
      user = User.create!
      user.with_lock do
        user.should be_locked
        User.first.should be_locked
      end
      user.should_not be_locked
      User.first.should_not be_locked
    end

    it "should allow execution within a lock" do
      user = User.create!
      user.with_lock do
        user.account_balance = 10
      end
      user.account_balance.should eq(10)
    end
  end
end
