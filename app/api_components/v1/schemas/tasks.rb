# frozen_string_literal: true

module V1
  module Schemas
    class Tasks
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::Task})
    end
  end
end
