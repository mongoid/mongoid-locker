require File.join(File.dirname(__FILE__), 'spec_helper')

describe Mongoid::Locker do
  before do
    # recreate the class for each spec
    class User
      include Mongoid::Document
      include Mongoid::Locker

      field :account_balance, :type => Integer # easier to test than Float
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
  end

  describe "#with_lock" do
    before { @user = User.create! }

    it "should lock and unlock the user" do
      @user.with_lock do
        @user.should be_locked
        User.first.should be_locked
      end

      @user.should_not be_locked
      @user.reload.should_not be_locked
    end

    it "shouldn't save the full document" do
      @user.with_lock do
        @user.account_balance = 10
      end

      @user.account_balance.should eq(10)
      User.first.account_balance.should be_nil
    end

    it "should handle errors gracefully" do
      expect {
        @user.with_lock do
          raise "booyah!"
        end
      }.to raise_error

      @user.reload.should_not be_locked
    end
  end
end
