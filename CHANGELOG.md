## Changelog

### 2.0.1 (Next)

* [#86](https://github.com/mongoid/mongoid-locker/pull/86): Upgraded to RuboCop 0.81.0 - [@dks17](https://github.com/dks17).
* [#86](https://github.com/mongoid/mongoid-locker/pull/86): Fixed issue with `ruby` `delegate` method - [@dks17](https://github.com/dks17).
* [#86](https://github.com/mongoid/mongoid-locker/pull/86): Update Ruby and JRUby versions for Travis config - [@dks17](https://github.com/dks17).
* Your contribution here.

### 2.0.0 (2019-10-23)

* [#79](https://github.com/mongoid/mongoid-locker/pull/79): Update find_and_lock and find_and_unlock methods - [@dks17](https://github.com/dks17).
* [#78](https://github.com/mongoid/mongoid-locker/pull/78): Upgrade to v2.0 - [@dks17](https://github.com/dks17).
* [#83](https://github.com/mongoid/mongoid-locker/pull/83): Upgraded to RuboCop 0.75.1 - [@dblock](https://github.com/dblock).

### 1.0.1 (2019-03-23)

* [#74](https://github.com/mongoid/mongoid-locker/pull/74): Add JRuby tests - [@dks17](https://github.com/dks17).
* [#68](https://github.com/mongoid/mongoid-locker/pull/68): Fix Rubocop offenses, refactoring, update `ruby` versions, add `COVERAGE` test env, update `.travis.yml` matrix - [@dks17](https://github.com/dks17).
* [#67](https://github.com/mongoid/mongoid-locker/pull/67): Deprecate `:wait` in favor of `:retries` option, which can attempt to grab a lock multiple times - [@afeld](https://github.com/afeld), [@dks17](https://github.com/dks17).
* [#66](https://github.com/mongoid/mongoid-locker/pull/66): Fix Mongoid::Locker::LockError for not persisted document - [@dks17](https://github.com/dks17).
* [#65](https://github.com/mongoid/mongoid-locker/pull/65): Drop `mongoid-compatibility` gem dependency - [@dks17](https://github.com/dks17).
* [#64](https://github.com/mongoid/mongoid-locker/pull/64): Exclude demo files from the gem - [@dks17](https://github.com/dks17).
* [#60](https://github.com/mongoid/mongoid-locker/pull/60): Drop support for `mongoid` version `2` and `3` - [@dks17](https://github.com/dks17).
* [#60](https://github.com/mongoid/mongoid-locker/pull/60): Add SimpleCov - [@dks17](https://github.com/dks17).

### 1.0.0 (2018-09-02)

* [#57](https://github.com/mongoid/mongoid-locker/pull/57): `Time.now` replaced by `Time.now.utc` - [@dks17](https://github.com/dks17).
* [#55](https://github.com/mongoid/mongoid-locker/pull/55): Customizable :locked_at and :locked_until fields - [@dks17](https://github.com/dks17).

### 0.3.6 (2018-04-18)

* [#52](https://github.com/mongoid/mongoid-locker/pull/52): Added support for Mongoid 7 - [@wuhuizuo](https://github.com/wuhuizuo).

### 0.3.5 (2017-01-24)

* [#43](https://github.com/mongoid/mongoid-locker/pull/43): Added support for Mongoid 6 - [@sivagollapalli](https://github.com/sivagollapalli).
* [#38](https://github.com/mongoid/mongoid-locker/issues/38): Fixed unlock already destroyed object - [@sivagollapalli](https://github.com/sivagollapalli).
* Removed Jeweler - [@afeld](https://github.com/afeld).
* [#46](https://github.com/mongoid/mongoid-locker/pull/46): Allow unlock when process no longer owns the lock or the lock times out - [@nchainani](https://github.com/nchainani).
* Library moved to the mongoid organization - [@afeld](https://github.com/afeld), [@dblock](https://github.com/dblock).
* [#48](https://github.com/mongoid/mongoid-locker/pull/48): Added Danger, PR linter - [@dblock](https://github.com/dblock).

### 0.3.4

* [#37](https://github.com/mongoid/mongoid-locker/pull/37): Fixed write concern for the lock record with Mongoid 5 - [@dblock](https://github.com/dblock).
* Don't query the document in Mongoid 5, better performance when acquiring lock - [@afeld](https://github.com/afeld).

### 0.3.3

* [#36](https://github.com/mongoid/mongoid-locker/pull/36): Added support for Mongoid 5 - [@dblock](https://github.com/dblock).

### 0.3.2

* [#34](https://github.com/mongoid/mongoid-locker/issues/34): Loosened Mongoid dependency - [@afeld](https://github.com/afeld).

### 0.3.1

* [#32](https://github.com/mongoid/mongoid-locker/pull/32): Fixed race condition, `undefined method '-' for nil:NilClass` - [@pschrammel](https://github.com/pschrammel).

### 0.3.0

* [#8](https://github.com/mongoid/mongoid-locker/issues/8): Changed exception class to be `Mongoid::Locker::LockError` - [@afeld](https://github.com/afeld), [@tolsen](https://github.com/tolsen).
* Dropped support for Rubinius 1.8-mode, since it seems to be broken w/ Mongoid 2.6 - [@afeld](https://github.com/afeld).
* [#8](https://github.com/mongoid/mongoid-locker/issues/12): Relaxed dependency on Mongoid - [@afeld](https://github.com/afeld).
* [#24](https://github.com/mongoid/mongoid-locker/pull/24): Added Mongoid 4 support - [@dblock](https://github.com/dblock).
* [#24](https://github.com/mongoid/mongoid-locker/pull/24): Dropped support for Ruby 1.8.x - [@dblock](https://github.com/dblock).
* Got rid of appraisal for testing multiple Mongoid versions - [@afeld](https://github.com/afeld).
* [#25](https://github.com/mongoid/mongoid-locker/pull/25): Added Rubocop, Ruby style linter - [@dblock](https://github.com/dblock).
* [#25](https://github.com/mongoid/mongoid-locker/pull/25): Fixed `:has_lock?` to always return a boolean - [@dblock](https://github.com/dblock).
* [#25](https://github.com/mongoid/mongoid-locker/pull/25): Upgraded RSpec to 3.x - [@dblock](https://github.com/dblock).
* [#9](https://github.com/mongoid/mongoid-locker/pull/9): Added `:retries` option to attempt to grab a lock multiple times - [@afeld](https://github.com/afeld), [@mooremo](https://github.com/mooremo).
* Added `:retry_sleep` to override duration between lock attempts - [@afeld](https://github.com/afeld).
* Reload document after acquiring a lock by default, which can be disabled with `:reload => false` - [@afeld](https://github.com/afeld).

### 0.2.1

* Fix for `update()` on Mongoid 3 - [@afeld](https://github.com/afeld).
* [#1](https://github.com/mongoid/mongoid-locker/issues/1): Automatically reload model after waiting - [@afeld](https://github.com/afeld).

### 0.2.0

* [#7](https://github.com/mongoid/mongoid-locker/issues/7): Handle recursive calls to `#with_lock` - [@afeld](https://github.com/afeld).
* Lock optimizations, particularly for large documents - [@afeld](https://github.com/afeld).
* [#5](https://github.com/mongoid/mongoid-locker/issues/5): Added Mongoid 3 support - [@afeld](https://github.com/afeld).

### 0.1.1

* [#5](https://github.com/mongoid/mongoid-locker/issues/5): Fix for subclasses - [@afeld](https://github.com/afeld).

### 0.1.0

* Initial public release - [@afeld](https://github.com/afeld).
