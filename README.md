# mongoid-locker [![Build Status](https://secure.travis-ci.org/afeld/mongoid-locker.png?branch=master)](http://travis-ci.org/afeld/mongoid-locker) [![Code Climate](https://codeclimate.com/github/afeld/mongoid-locker.png)](https://codeclimate.com/github/afeld/mongoid-locker)

Document-level locking for MongoDB via Mongoid.  The need arose at [Jux](https://jux.com) from multiple processes on multiple servers trying to act upon the same document and stepping on each other's toes.  Mongoid-Locker is an easy way to ensure only one process can perform a certain operation on a document at a time.

[Tested](http://travis-ci.org/afeld/mongoid-locker) against MRI 1.9.3, 2.0.0 and 2.1.2, Rubinius 2.x, and JRuby 1.9 with Mongoid 2, 3 and 4 ([where supported](http://travis-ci.org/#!/afeld/mongoid-locker)).

## Usage

Add to your `Gemfile`:

```ruby
gem 'mongoid-locker', '~> 0.2'
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

`#with_lock` takes an optional [handful of options around retrying](http://rdoc.info/github/afeld/mongoid-locker/Mongoid/Locker:with_lock), so make sure to take a look.

The default timeout can also be set on a per-class basis:

```ruby
class QueueItem
  # ...
  timeout_lock_after 10
end
```

Note that these locks are only enforced when using `#with_lock`, not at the database level.  It is useful for transactional operations, where you can make atomic modification of the document with checks.  For exmple, you could deduct a purchase from a user's balance... _unless_ they are broke.

More in-depth method documentation can be found at [rdoc.info](http://rdoc.info/github/afeld/mongoid-locker/frames).  Enjoy!
