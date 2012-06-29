# mongoid-locker [![Build Status](https://secure.travis-ci.org/afeld/mongoid-locker.png)](http://travis-ci.org/afeld/mongoid-locker)

Document-level locking for MongoDB via Mongoid.  The need arose at @Jux from multiple processes on multiple servers trying to act upon the same document and stepping on each other's toes.  Mongoid-Locker is an easy way to ensure only one process can perform a certain operation on a document at a time.

[Tested](http://travis-ci.org/afeld/mongoid-locker) against MRI 1.8.7, 1.9.2 and 1.9.3, Rubinius 1.8 and 1.9, and JRuby 1.8 and 1.9.

## Usage

In the model you wish to lock, include `Mongoid::Locker` after `Mongoid::Document`.  For example:

```ruby
class User
    include Mongoid::Document
    include Mongoid::Locker
    
    field :account_balance, :type => Float
end
```

Then, execute any code you like in a block like so:

```ruby
user.with_lock do
    user.account_balance -= 100.00
    user.save!
end
```

`#with_lock` takes a couple options as a hash:

* `timeout`: The amount of time until a lock expires, in seconds.  Defaults to `5`.
* `wait`: If a lock exists on the document, wait until that lock expires and try again.  Defaults to `false`.

The default timeout can also be set on a per-class basis:

```ruby
class User
    # ...
    timeout_lock_after 10
end
```

Enjoy!

## Contributing

Pull requests are welcome.  To run tests:

    $ bundle install
    $ rake

To auto-run tests as you code:

    $ bundle install
    $ guard
