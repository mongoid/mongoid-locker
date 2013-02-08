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

    @user = User.create! :account_balance => 20
  end

  after do
    User.delete_all
    remove_class User
  end


  describe "#locked?" do
    it "shouldn't be locked when created" do
      @user.locked?.should be_false
    end

    it "should be true when locked" do
      @user.with_lock do
        @user.locked?.should be_true
      end
    end

    it "should respect the expiration" do
      User.timeout_lock_after 1

      @user.with_lock do
        sleep 2
        @user.locked?.should be_false
      end
    end

    it "should be true for a different instance" do
      @user.with_lock do
        User.first.locked?.should be_true
      end
    end
  end

  describe "#has_lock?" do
    it "shouldn't be has_lock when created" do
      @user.has_lock?.should be_false
    end

    it "should be true when has_lock" do
      @user.with_lock do
        @user.has_lock?.should be_true
      end
    end

    it "should respect the expiration" do
      User.timeout_lock_after 1

      @user.with_lock do
        sleep 2
        @user.has_lock?.should be_false
      end
    end

    it "should be false for a different instance" do
      @user.with_lock do
        User.first.has_lock?.should be_false
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
      User.first.account_balance.should eq(20)
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

    it "should handle recursive calls" do
      @user.with_lock do
        @user.with_lock do
          @user.account_balance = 10
        end
      end

      @user.account_balance.should eq(10)
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

    it "should, by default, reload the row after acquiring the lock" do
      @user.should_receive(:reload)
      @user.with_lock do
        # no-op
      end
    end

    it "should allow override of the default reload behavior" do
      @user.should_not_receive(:reload)
      @user.with_lock :reload => false do
        # no-op
      end
    end

    it "should, by default, not retry" do
      @user.should_receive(:acquire_lock).once.and_return(true)
      @user.with_lock do
        user_dup = User.first

        user_dup.with_lock do
          # no-op
        end
      end
    end

    it "should retry the number of times given, if desired" do
      @user.stub(:acquire_lock).and_return(false)
      Mongoid::Locker::Wrapper.stub(:locked_until => Time.now)

      @user.should_receive(:acquire_lock).exactly(6).times
      expect{
        @user.with_lock :retries => 5 do
          # no-op
        end
      }.to raise_error(Mongoid::LockError)
    end

    it "should, by default, when retrying, sleep until the lock expires" do
      @user.stub(:acquire_lock).and_return(false)
      Mongoid::Locker::Wrapper.stub(:locked_until => (Time.now + 5.seconds))
      @user.stub(:sleep) {|time| time.should be_within(0.1).of(5)}

      expect{
        @user.with_lock :retries => 1 do
          # no-op
        end
      }.to raise_error(Mongoid::LockError)
    end

    it "should sleep for the time given, if desired" do
      @user.stub(:acquire_lock).and_return(false)
      @user.stub(:sleep) {|time| time.should be_within(0.1).of(3)}

      expect{
        @user.with_lock({:retries => 1, :retry_sleep => 3}) do
          # no-op
        end
      }.to raise_error(Mongoid::LockError)
    end

    it "should override the default timeout" do
      User.timeout_lock_after 1

      expiration = (Time.now + 3).to_i
      @user.with_lock :timeout => 3 do
        @user.locked_until.to_i.should eq(expiration)
      end
    end

    it "should reload the document if it needs to wait for a lock" do
      User.timeout_lock_after 1

      @user.with_lock do
        user_dup = User.first

        @user.account_balance = 10
        @user.save!

        user_dup.account_balance.should eq(20)
        user_dup.with_lock :wait => true do
          user_dup.account_balance.should eq(10)
        end
      end
    end

    it "should succeed for subclasses" do
      class Admin < User
      end

      admin = Admin.create!

      admin.with_lock do
        admin.should be_locked
        Admin.first.should be_locked
      end

      admin.should_not be_locked
      admin.reload.should_not be_locked

      remove_class Admin
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

  describe ".locked" do
    it "should return the locked documents" do
      user2 = User.create!

      @user.with_lock do
        User.locked.to_a.should eq([@user])
      end
    end
  end

  describe ".unlocked" do
    it "should return the unlocked documents" do
      user2 = User.create!

      @user.with_lock do
        User.unlocked.to_a.should eq([user2])
      end
    end
  end
end
