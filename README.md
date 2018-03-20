# mongoid-locker
[![Gem Version](https://badge.fury.io/rb/mongoid-locker.svg)](http://badge.fury.io/rb/mongoid-locker)
[![Build Status](https://secure.travis-ci.org/mongoid/mongoid-locker.svg?branch=master)](http://travis-ci.org/mongoid/mongoid-locker)
[![Code Climate](https://codeclimate.com/github/mongoid/mongoid-locker.svg)](https://codeclimate.com/github/mongoid/mongoid-locker)

Document-level locking for MongoDB via Mongoid.  The need arose at [Jux](https://jux.com) from multiple processes on multiple servers trying to act upon the same document and stepping on each other's toes.  Mongoid-Locker is an easy way to ensure only one process can perform a certain operation on a document at a time.

[Tested](http://travis-ci.org/mongoid/mongoid-locker) against:
- MRI: `2.3.6`, `2.4.3`, `2.5.0` 
- Mongoid: `2`, `3`, `4`, `5`, `6`, `7`

See [.travis.yml](.travis.yml) for the latest test matrix.

## Usage

Add to your `Gemfile`:

```ruby
gem 'mongoid-locker'
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

The `#with_lock` function takes an optional [handful of options around retrying](http://rdoc.info/github/mongoid/mongoid-locker/Mongoid/Locker:with_lock), so make sure to take a look.

The default timeout can also be set on a per-class basis:

```ruby
class QueueItem
  # ...
  timeout_lock_after 10
end
```

Note that these locks are only enforced when using `#with_lock`, not at the database level. It's useful for transactional operations, where you can make atomic modification of the document with checks.  For example, you could deduct a purchase from a user's balance ... _unless_ they are broke.

More in-depth method documentation can be found at [rdoc.info](http://rdoc.info/github/mongoid/mongoid-locker/frames).

## Copyright & License

Copyright (c) 2012-2018 Aidan Feldman & Contributors

MIT License, see [LICENSE](LICENSE.txt) for more information.
