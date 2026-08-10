# frozen_string_literal: true

require 'dynamic_fields_for_rails/version'

# rubocop:disable Style/ClassVars
module DynamicFieldsForRails
  class Engine < Rails::Engine
  end

  mattr_accessor :add_css_classes
  @@add_css_classes = 'add_fields'

  mattr_accessor :delete_css_classes
  @@delete_css_classes = 'remove_fields'

  def self.setup
    yield self
  end
end
# rubocop:enable Style/ClassVars
