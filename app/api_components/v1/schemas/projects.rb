# frozen_string_literal: true

module V1
  module Schemas
    class Projects
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::Project})
    end
  end
end
