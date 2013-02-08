#!/bin/sh

# Die on failures
set -e

BUNDLE_GEMFILE=gemfiles/mongoid2.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/mongoid3.gemfile bundle install
bundle install
