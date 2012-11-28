!SLIDE

# Mongoid-Locker

[github.com/afeld/mongoid-locker](https://github.com/afeld/mongoid-locker)

## Aidan Feldman, [Jux.com](https://jux.com)

!SLIDE

![Instagram diagram](instagram.png)

!SLIDE

# Jux needed a queue.

* Distributed, but synchronized
* No add'l DB
* No add'l hassle (managing workers, etc.)

!SLIDE

* Thread
  - \+ Distributed
  - – Not synchronized
* Many workers
  - \+ Distributed
  - – Not synchronized
* One worker
  - \+ Synchronized
  - – Not distributed
  - – Single POF

!SLIDE

    @@@ ruby
    require 'rubygems'
    require 'mongoid-locker'
    Mongoid.load!('config/mongoid.yml', :development)


    class User
      include Mongoid::Document
      # include Mongoid::Locker

      field :balance, type: Float
    end

    # cleanup
    User.destroy_all

    bob = User.create!(balance: 100.00)

!SLIDE

# Atomic Operations

    @@@ ruby
    class User
      def purchase(amount)
        if amount > self.balance
          raise "Can't have negative balance!" 
        else
          # deduct *atomically*
          self.inc(:balance, -1 * amount)
          # a.k.a.
          # db.users.update({_id: ...}, {$inc: {balance: ...}})

          puts "cha-ching!"
        end
      end
    end

    bob.purchase(5.10) #=> "cha-ching!"
    bob.purchase(110.53) #=> "Can't have negative balance!"

!SLIDE

# All fine, right?

!SLIDE

    @@@ ruby
    class User
      def purchase(amount)
        if amount > self.balance
          raise "Can't have negative balance!" 
        else
          # artificial delay
          print 'has enough money...waiting for ENTER > '
          gets

          self.inc(:balance, -1 * amount)
          puts "cha-ching!"
        end
      end
    end

!SLIDE

    @@@ ruby
    # shell 1
    bob.purchase(10.00)

    # shell 2
    also_bob = User.first
    also_bob.purchase(95.00)

!SLIDE

# oops.

!SLIDE

    @@@ ruby
    class User
      # add doc-level locking
      include Mongoid::Locker
      timeout_lock_after 20

      def purchase(amount)
        # only one at a time
        self.with_lock(wait: true) do
          # after the `wait`, will have updated `balance`

          if amount > self.balance
            raise "Can't have negative balance!" 
          else
            print 'has enough money...waiting for ENTER > '
            gets

            self.inc(:balance, -1 * amount)
            puts "cha-ching!"
          end
        end
      end
    end

!SLIDE

# Summary

* Easy document-level locking
* Useful for queueing or pseudo-transactions
* No additional dependencies

!SLIDE

# Fin.

[afeld/mongoid-locker](https://github.com/afeld/mongoid-locker)

----------------

## Aidan Feldman, [Jux.com](https://jux.com)

[@aidanfeldman](https://twitter.com/aidanfeldman)

[afeld.me](http://afeld.me)
