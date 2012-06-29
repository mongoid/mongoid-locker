require File.join(File.dirname(__FILE__), 'spec_helper')

describe Mongoid::Locker do
  def remove_class klass
    Object.send :remove_const, klass.to_s.to_sym
  end

  before do
    # recreate the class for each spec
    class User
      include Mongoid::Document
      include Mongoid::Locker

      field :account_balance, :type => Integer # easier to test than Float
    end

    @user = User.create!
  end

  after do
    User.delete_all
    remove_class User
  end


  describe "#locked?" do
    it "shouldn't be locked when created" do
      @user.should_not be_locked
    end

    it "should respect the expiration" do
      User.timeout_lock_after 1

      @user.with_lock do
        sleep 2
        @user.should_not be_locked
      end
    end
  end

  describe "#with_lock" do
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

    it "should complain if trying to lock locked doc" do
      @user.with_lock do
        user_dup = User.first

        expect {
          user_dup.with_lock do
            fail "shouldn't get the lock"
          end
        }.to raise_error(Mongoid::LockError)
      end
    end

    it "should wait until the lock times out, if desired" do
      User.timeout_lock_after 1

      @user.with_lock do
        user_dup = User.first

        user_dup.with_lock :wait => true do
          user_dup.account_balance = 10
          user_dup.save!
        end
      end

      @user.reload.account_balance.should eq(10)
    end

    it "should override the default timeout" do
      User.timeout_lock_after 1

      expiration = (Time.now + 3).to_i
      @user.with_lock :timeout => 3 do
        @user.locked_until.to_i.should eq(expiration)
      end
    end
  end

  describe ".timeout_lock_after" do
    it "should ignore the lock if it has timed out" do
      User.timeout_lock_after 1

      @user.with_lock do
        user_dup = User.first
        sleep 2

        user_dup.with_lock do
          user_dup.account_balance = 10
          user_dup.save!
        end
      end

      @user.reload.account_balance.should eq(10)
    end

    it "should be independent for different classes" do
      class Account
        include Mongoid::Document
        include Mongoid::Locker
      end

      User.timeout_lock_after 1
      Account.timeout_lock_after 2

      User.lock_timeout.should eq(1)

      remove_class Account
    end
  end
end
