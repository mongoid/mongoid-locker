# Contributing

Pull requests are welcome. To set up:

    $ bundle install

To run tests:

    $ bundle exec rake

To run tests for Mongoid 3:

    $ rm Gemfile.lock
    $ BUNDLE_GEMFILE=gemfiles/mongoid_3.gemfile bundle install
    $ BUNDLE_GEMFILE=gemfiles/mongoid_3.gemfile bundle exec rake

To auto-run tests as you code:

    $ bundle exec guard
