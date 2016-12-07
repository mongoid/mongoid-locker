# Changelog

## Next ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.3.5...master?w=1))

* your contribution here
* Unlock already destroyed object - #38 

## 0.3.4 ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.3.4...master?w=1))

* fixed write concern for the lock record with Mongoid 5
* don't query the document in Mongoid 5, better performance when acquiring lock

## 0.3.3 ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.3.3...master?w=1))

* support Mongoid 5 - #36

## 0.3.2 ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.3.1...v0.3.2?w=1))

* loosen Mongoid dependency - #33

## 0.3.1 ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.3.0...v0.3.1?w=1))

* fixed race condition, `undefined method '-' for nil:NilClass` - #18

## 0.3.0 ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.2.1...v0.3.0?w=1))

* change exception class to be `Mongoid::Locker::LockError` - #8
* drop support for Rubinius 1.8-mode, since it seems to be [broken w/ Mongoid 2.6](https://travis-ci.org/mongoid/mongoid/jobs/4594000)
* relax dependency on Mongoid - #12
* add Mongoid 4 support
* drop support for Ruby 1.8.x
* got rid of appraisal for testing multiple Mongoid versions
* added Rubocop, Ruby style linter
* fixed `:has_lock?` to always return a boolean
* upgraded RSpec to 3.x

Thanks to @mooremo, @yanowitz and @nchainani (#9):

* add `:retries` option to attempt to grab a lock multiple times - #2
* add `:retry_sleep` to override duration between lock attempts
* reload document after acquiring a lock by default, which can be disabled with `:reload => false`

## 0.2.1 ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.2.0...v0.2.1?w=1))

* fix for `update()` on Mongoid 3
* automatically reload model after waiting - #1

## 0.2.0 ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.1.1...v0.2.0?w=1))

* handle recursive calls to `#with_lock` - #7
* lock optimizations, particularly for large documents
* add Mongoid 3 support - #3

## 0.1.1 ([diff](https://github.com/mongoid/mongoid-locker/compare/v0.1.0...v0.1.1?w=1))

* fix for subclasses - #5

## 0.1.0

Initial release!
