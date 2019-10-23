## Upgrading Mongoid-Locker

## Upgrading to 2.0.0

Mongoid-Locker supports only `5`, `6` and `7` versions of Mongoid.
Since this version `Mongoid::Locker` uses unique name of locking and time is set by MongoDB. `Mongoid::Locker` no longer uses `locked_until` field and this field may be deleted with `User.all.unset(:locked_until)`. You must define new `locking_name` field of `String` type.

```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locking_name, type: String
  field :locked_at, type: Time
end
```

The options `:timeout` and `retry_sleep` of `#with_lock` method was deprecated and have no effect. For details see [RubyDoc.info](https://www.rubydoc.info/gems/mongoid-locker/2.0.0/Mongoid/Locker#with_lock-instance_method).
If you handle `Mongoid::Locker::LockError` error then this error should be renamed to `Mongoid::Locker::Errors::DocumentCouldNotGetLock`.

### Upgrading to 1.0.0

`Mongoid::Locker` no longer defines `locked_at` and `locked_until` fields when included. You must define these fields manually.

```ruby
class User
  include Mongoid::Document
  include Mongoid::Locker

  field :locked_at, type: Time
  field :locked_until, type: Time
end
```

You can customize the fields used with a `locker` class method or via a global `configure`. See [Customizable :locked_at and :locked_until field names](https://github.com/mongoid/mongoid-locker#customizable-locked_at-and-locked_until-field-names) for more information.

See [#55](https://github.com/mongoid/mongoid-locker/pull/55) for more information.
