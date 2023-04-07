# frozen_string_literal: true

if ENV["RAILS_TEST_COVERAGE"]
  require "simplecov"
  require "simplecov-console"
  require "simplecov-html"

  formatters = [
    SimpleCov::Formatter::Console,
    SimpleCov::Formatter::HTMLFormatter
  ]
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(formatters)
  SimpleCov.start("rails")
end

ENV["RAILS_ENV"] = "test"
require File.expand_path("../config/environment", __dir__)

require "rails/test_help"
require "minitest/rails"
require "minitest/pride"

# https://github.com/rails/rails/issues/31324
Minitest::Rails::TestUnit = Rails::TestUnit if ActionPack::VERSION::STRING >= "5.2.0"

require "active_record/fixtures"
require "database_cleaner"

require "faker"

require "sidekiq/testing"
Sidekiq::Testing.fake!

# database cleaner
DatabaseCleaner.strategy = :transaction

# rubocop:disable Style/ClassAndModuleChildren
class ActionDispatch::IntegrationTest
  fixtures :all
  include Devise::Test::IntegrationHelpers
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
  fixtures :all
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

class ActionMailer::TestCase
  fixtures :all

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end
# rubocop:enable Style/ClassAndModuleChildren
