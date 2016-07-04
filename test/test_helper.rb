# encoding: utf-8
# frozen_string_literal: true
require 'coveralls'
Coveralls.wear!('rails')

ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require "rails/test_help"
require "minitest/rails"
require "minitest/hell"
require "minitest/mock"
require 'mocha/mini_test'

require "faker"

require "active_record/fixtures"

require 'sidekiq/testing'
Sidekiq::Testing.fake!

# helper
require "support/session_helper"
require "database_cleaner"

# database cleaner
DatabaseCleaner.strategy = :transaction

# rubocop:disable Style/ClassAndModuleChildren
class ActionController::TestCase
  fixtures :all
  include Devise::Test::ControllerHelpers
  include SessionHelper
  ActiveRecord::Migration.check_pending!

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end

class ActionView::TestCase
  fixtures :all
  include Devise::Test::ControllerHelpers

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end

  after do
    Sidekiq::Worker.clear_all
  end
end
