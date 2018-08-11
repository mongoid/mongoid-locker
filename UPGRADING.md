## Upgrading Mongoid Locker

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
