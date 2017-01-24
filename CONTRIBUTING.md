# Contributing

Pull requests are welcome. To set up:

    $ bundle install

To run tests:

    $ bundle exec rake

To run tests for an older version of Mongoid:

    $ rm Gemfile.lock
    $ export MONGOID_VERSION=4
    $ bundle install
    $ bundle exec rake

To auto-run tests as you code:

    $ bundle exec guard
