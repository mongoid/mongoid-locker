# frozen_string_literal: true

require 'mongoid'

require 'mongoid/locker'
require 'mongoid/locker/version'
require 'mongoid/locker/wrapper'
require 'mongoid/locker/errors'

# Load english locale by default.
I18n.load_path << File.join(File.dirname(__FILE__), 'config/locales', 'en.yml')
