# Mongoid-Locker

[![Gem Version](https://badge.fury.io/rb/mongoid-locker.svg)](https://badge.fury.io/rb/mongoid-locker)
[![Test Status](https://github.com/mongoid/mongoid-locker/workflows/Test/badge.svg)](https://github.com/mongoid/mongoid-locker/actions)
[![Build Status](https://travis-ci.org/mongoid/mongoid-locker.svg?branch=master)](https://travis-ci.org/mongoid/mongoid-locker)
[![Maintainability](https://api.codeclimate.com/v1/badges/04ee4ee75ff54659300a/maintainability)](https://codeclimate.com/github/mongoid/mongoid-locker/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/04ee4ee75ff54659300a/test_coverage)](https://codeclimate.com/github/mongoid/mongoid-locker/test_coverage)

Document-level optimistic locking for MongoDB via Mongoid. Mongoid-Locker is an easy way to ensure only one process can perform a certain operation on a document at a time.

**NOTE:** Since version `2` Mongoid-Locker relies on MongoDB server time and not current client time, and does not perform any time calculation to get lock or release it. The basis of the current version are unique name of locking and time is set by MongoDB.

**NOTE:** Please refer to [1-x-stable](https://github.com/mongoid/mongoid-locker/tree/1-x-stable) branch for `1.x.x` documentation. See the [UPGRADING](UPGRADING.md) guide and [CHANGELOG](CHANGELOG.md) for an overview of the changes.

[Tested](https://travis-ci.org/mongoid/mongoid-locker) against:
- MRI: `2.3.8`, `2.4.7`, `2.5.7`, `2.6.6`, `2.7.1`
- JRuby `9.1.17.0`, `9.2.11.1`
- Mongoid: `5`, `6`, `7`

See [.travis.yml](.travis.yml) for the latest test matrix.

## Usage

Add to your `Gemfile`:

```ruby
gem 'mongoid-locker'
```

and run `bundle install`. In the model you wish to lock, include `Mongoid::Locker` after `Mongoid::Document`. For example:

```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locking_name, type: String
  field :locked_at, type: Time

  field :age, type: Integer
end
```

Then, execute any code you like in a block like so:

```ruby
user.with_lock do
  user.age = 17
  user.save!
end
```

The `#with_lock` function takes an optional handful of options, so make sure to take a look.

Note that these locks are only enforced when using `#with_lock`, not at the database level. It's useful for transactional operations, where you can make atomic modification of the document with checks. For example, you could deduct a purchase from a user's balance ... _unless_ they are broke.

More in-depth method documentation can be found at [RubyDoc.info](https://www.rubydoc.info/gems/mongoid-locker).

### Customizable :locking_name and :locked_at field names
By default, Locker uses fields with `:locking_name` and `:locked_at` names which should be defined in a model.
```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locking_name, type: String
  field :locked_at, type: Time
end
```

Use `Mongoid::Locker.configure` to setup parameters which used by Locker for all models where it's included.
```ruby
Mongoid::Locker.configure do |config|
  config.locking_name_field = :global_locking_name
  config.locked_at_field    = :global_locked_at
end

class User
  include Mongoid::Document
  include Mongoid::Locker

  field :global_locking_name, type: String
  field :global_locked_at, type: Time
end
```

The `locker` method in your model accepts options to setup parameters for the model.
```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locker_locking_name, type: String
  field :locker_locked_at, type: Time

  locker locked_at_field: :locker_locking_name,
         locked_at_field: :locker_locked_at
end
```

### Available parameters for Mongoid::Locker, a class where it's included
| parameter | default | options | description |
|---|---|---|---|
| locking_name_field | `:locking_name` | any field name | field where name of locking is storing, must be of type `String` |
| locked_at_field | `:locked_at` | any field name | field where it is storing the time of beginning a lock of a document, must be of type `Time` |
| lock_timeout | `5` | | within this time (in seconds) a document is considered as locked |
| locker_write_concern | `{ w: 1 }` | see [MongoDB Write Concern](https://docs.mongodb.com/manual/reference/write-concern/#write-concern-specification)| a write concern only used for lock and unlock operations |
| maximum_backoff | `60.0` | | the highest timeout (in seconds) between retires to lock a document, reaching that value `#with_lock` method raises `Mongoid::Locker::Errors::DocumentCouldNotGetLock` |
| backoff_algorithm | `:exponential_backoff` | `:locked_at_backoff` or [custom algorithm](#custom-backoff_algorithm-and-locking_name_generator) | algorithm used for timeout calculating between retries to lock a document|
| locking_name_generator | `:secure_locking_name` | [custom generator](#custom-backoff_algorithm-and-locking_name_generator) | generator used to generate unique name of a lock |

For instances of a class where `Mongoid::Locker` is included, all parameters of a class are available for reading.
```ruby
  document.lock_timeout
  #=> 5
```

### Custom :backoff_algorithm and :locking_name_generator
A method which is defined in `Mongoid::Locker` are available in a class where it is included.

Method `#with_lock` passes to the methods a document to which apply `#with_lock` and a hash of options. The hash may look like this:
```ruby
  { retries: Infinity, reload: true, attempt: 0, locking_name: "71c1ccd4-72d9-4a83-bbed-adf65803bd5d" }
```

A custom backoff algorithmoff **must return** a value more or equal `maximum_backoff` value to force `#with_lock` quit trying to lock a document, otherwise `#with_lock` will be trying to lock a document `INFINITY` times.
```ruby
Mongoid::Locker.configure do |config|
  config.backoff_algorithm = :custom_backoff
end

module Mongoid
  module Locker
    def self.custom_backoff(doc, _opts)
      rand > 0.5 ? 5 : doc.maximum_backoff
    end
  end
end
```

A custom locking name generator **must return** a string to secure uniqueness name of locking.
```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  locker locking_name_generator: :custom_locking_name

  field :locker_locking_name, type: String
  field :locker_locked_at, type: Time

  def self.custom_locking_name(_doc, _opts)
    SecureRandom.uuid
  end
```

## Testing with RSpec
Please see examples in [test_examples_spec.rb](spec/test_examples_spec.rb) file.

## Copyright & License

Copyright (c) 2012-2020 Aidan Feldman & Contributors

MIT License, see [LICENSE](LICENSE.txt) for more information.
