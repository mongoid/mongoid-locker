# mongoid-locker
[![Gem Version](https://badge.fury.io/rb/mongoid-locker.svg)](https://badge.fury.io/rb/mongoid-locker)
[![Build Status](https://travis-ci.org/mongoid/mongoid-locker.svg?branch=master)](https://travis-ci.org/mongoid/mongoid-locker)
[![Maintainability](https://api.codeclimate.com/v1/badges/04ee4ee75ff54659300a/maintainability)](https://codeclimate.com/github/mongoid/mongoid-locker/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/04ee4ee75ff54659300a/test_coverage)](https://codeclimate.com/github/mongoid/mongoid-locker/test_coverage)

Document-level locking for MongoDB via Mongoid. Mongoid-Locker is an easy way to ensure only one process can perform a certain operation on a document at a time.

[Tested](https://travis-ci.org/mongoid/mongoid-locker) against:
- MRI: `2.3.8`, `2.4.5`, `2.5.3`
- JRuby `9.1.17.0`, `9.2.4.0`
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

### Customizable :locked_at and :locked_until field names
By default, Locker uses fields with `:locked_at` and `:locked_until` names which should be defined in a model.
```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locked_at, type: Time
  field :locked_until, type: Time
end
```

Use `Mongoid::Locker.configure` to setup field names which used by Locker for all models where it's included.
```ruby
Mongoid::Locker.configure do |config|
  config.locked_at_field = :global_locked_at
  config.locked_until_field = :global_locked_until
end

class User
  include Mongoid::Document
  include Mongoid::Locker

  field :global_locked_at, type: Time
  field :global_locked_until, type: Time
end
```

The `locker` method in your model accepts `:locked_at_field` and `:locked_until_field` options to setup field names which used by Locker for the model. This can be useful when another library uses the same field for different purposes.
```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locker_locked_at, type: Time
  field :locker_locked_until, type: Time

  locker locked_at_field: :locker_locked_at,
         locked_until_field: :locker_locked_until
end
```

## Copyright & License

Copyright (c) 2012-2018 Aidan Feldman & Contributors

MIT License, see [LICENSE](LICENSE.txt) for more information.
