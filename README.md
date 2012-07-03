# mongoid-locker [![Build Status](https://secure.travis-ci.org/afeld/mongoid-locker.png)](http://travis-ci.org/afeld/mongoid-locker)

Document-level locking for MongoDB via Mongoid.  The need arose at [Jux](https://jux.com) from multiple processes on multiple servers trying to act upon the same document and stepping on each other's toes.  Mongoid-Locker is an easy way to ensure only one process can perform a certain operation on a document at a time.

[Tested](http://travis-ci.org/afeld/mongoid-locker) against MRI 1.8.7, 1.9.2 and 1.9.3, Rubinius 1.8 and 1.9, and JRuby 1.8 and 1.9.

## Usage

Add to your `Gemfile`:

```ruby
gem 'mongoid-locker', '~> 0.1.0'
```

and run `bundle install`.  In the model you wish to lock, include `Mongoid::Locker` after `Mongoid::Document`.  For example:

```ruby
class QueueItem
  include Mongoid::Document
  include Mongoid::Locker

  field :completed_at, :type => Time
end
```

Then, execute any code you like in a block like so:

```ruby
queue_item.with_lock do

  # do stuff

  queue_item.completed_at = Time.now
  queue_item.save!
end
```

`#with_lock` takes a couple options as a hash:

* `timeout`: The amount of time until a lock expires, in seconds.  Defaults to `5`.
* `wait`: If a lock exists on the document, wait until that lock expires and try again.  Defaults to `false`.

The default timeout can also be set on a per-class basis:

```ruby
class QueueItem
  # ...
  timeout_lock_after 10
end
```

Note that these locks are only enforced when using `#with_lock`, not at the database level.  It is useful for transactional operations, where you can make atomic modification of the document with checks.  For exmple, you could deduct a purchase from a user's balance... _unless_ they are broke.

More in-depth method documentation can be found at [rdoc.info](http://rdoc.info/github/afeld/mongoid-locker/frames).  Enjoy!

## Contributing

Pull requests are welcome.  To run tests:

    $ bundle install
    $ rake

To auto-run tests as you code:

    $ bundle install
    $ guard
