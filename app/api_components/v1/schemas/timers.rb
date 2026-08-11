# frozen_string_literal: true

module V1
  module Schemas
    class Timers
      include OpenapiRuby::Components::Base

      schema({type: :array, items: V1::Schemas::Timer})
    end
  end
end
