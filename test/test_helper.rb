ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

if ENV['CODECLIMATE_REPO_TOKEN'].present?
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end

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
  include Devise::TestHelpers
  include SessionHelper
  ActiveRecord::Migration.check_pending!

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
