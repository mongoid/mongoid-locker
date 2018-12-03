# mongoid-locker
[![Gem Version](https://badge.fury.io/rb/mongoid-locker.svg)](https://badge.fury.io/rb/mongoid-locker)
[![Build Status](https://travis-ci.org/mongoid/mongoid-locker.svg?branch=master)](https://travis-ci.org/mongoid/mongoid-locker)
[![Maintainability](https://api.codeclimate.com/v1/badges/04ee4ee75ff54659300a/maintainability)](https://codeclimate.com/github/mongoid/mongoid-locker/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/04ee4ee75ff54659300a/test_coverage)](https://codeclimate.com/github/mongoid/mongoid-locker/test_coverage)

Document-level locking for MongoDB via Mongoid. Mongoid-Locker is an easy way to ensure only one process can perform a certain operation on a document at a time.

[Tested](https://travis-ci.org/mongoid/mongoid-locker) against:
- MRI: `2.3.8`, `2.4.5`, `2.5.3`
- Mongoid: `4`, `5`, `6`, `7`

See [.travis.yml](.travis.yml) for the latest test matrix.

## Usage

Add to your `Gemfile`:

```ruby
gem 'mongoid-locker'
```

and run `bundle install`. In the model you wish to lock, include `Mongoid::Locker` after `Mongoid::Document`. For example:

```ruby
class QueueItem
  include Mongoid::Document
  include Mongoid::Locker

  field :locked_at, type: Time
  field :locked_until, type: Time
  field :locked_name, type: String

  field :completed_at, type: Time
end
```

Then, execute any code you like in a block like so:

```ruby
queue_item.with_lock do

  # do stuff

  queue_item.completed_at = Time.now.utc
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

Note that these locks are only enforced when using `#with_lock`, not at the database level. It's useful for transactional operations, where you can make atomic modification of the document with checks. For example, you could deduct a purchase from a user's balance ... _unless_ they are broke.

More in-depth method documentation can be found at [rdoc.info](http://rdoc.info/github/mongoid/mongoid-locker/frames).

### locked_name field format
When a document has lock the `locked_name` field contains name of the current lock:
```ruby
queue_item.with_lock do
  queue_item.locked_name # => "5d441f8b#0"
end
```
The lock name `"5d441f8b#0"` consists of two parts are split with number sign `#`. The first part is hexadecimal string - immediate name of the lock, generated randomly before locking. And the second part is number of attempt with which the lock was succeeded. With each retry the number of attempt increases by `1`. Number `0` means that the locking was succeeded at once without any additional retries.

### Customizable :locked_at, :locked_until, and :locked_name field names
By default, Locker uses fields with `:locked_at`, `:locked_until`, and `:locked_name` names which should be defined in a model.
```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locked_at, type: Time
  field :locked_until, type: Time
  field :locked_name, type: String
end
```

Use `Mongoid::Locker.configure` to setup field names which used by Locker for all models where it's included.
```ruby
Mongoid::Locker.configure do |config|
  config.locked_at_field = :global_locked_at
  config.locked_until_field = :global_locked_until
  config.locked_name_field = :global_locked_name
end

class User
  include Mongoid::Document
  include Mongoid::Locker

  field :global_locked_at, type: Time
  field :global_locked_until, type: Time
  field :global_locked_name, type: String
end
```

The `locker` method in your model accepts `:locked_at_field`, `:locked_until_field`, and `:locked_name_field` options to setup field names which used by Locker for the model. This can be useful when another library uses the same field for different purposes.
```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locker_locked_at, type: Time
  field :locker_locked_until, type: Time
  field :locker_locked_name, type: String

  locker locked_at_field: :locker_locked_at,
         locked_until_field: :locker_locked_until,
         locked_name_field: :locker_locked_name
end
```

## Copyright & License

Copyright (c) 2012-2018 Aidan Feldman & Contributors

MIT License, see [LICENSE](LICENSE.txt) for more information.
