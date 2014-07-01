# Contributing

Pull requests are welcome.  To set up:

    $ bundle install

To run tests:

    $ rake

To run tests for Mongoid 3:

    $ rm Gemfile.lock
    $ MONGOID_VERSION=3 bundle install
    $ MONGOID_VERSION=3 rake

To auto-run 3 tests as you code:

    $ bundle exec guard
