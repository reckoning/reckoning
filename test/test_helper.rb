ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)

require "rails/test_help"
require "minitest/rails"

require "database_cleaner"

# database cleaner
DatabaseCleaner.strategy = :transaction

# factory girl
require "factory_girl"
FactoryGirl.find_definitions

class Minitest::Spec
  include FactoryGirl::Syntax::Methods
end


class ActiveSupport::TestCase
  include FactoryGirl::Syntax::Methods
end

class ActionController::TestCase
  include FactoryGirl::Syntax::Methods
  include Devise::TestHelpers
  ActiveRecord::Migration.check_pending!

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end
