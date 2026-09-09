# frozen_string_literal: true

module V1
  module Schemas
    class AfaTypes
      include OpenapiRuby::Components::Base

      schema({type: :array, items: ::V1::Schemas::AfaType})
    end
  end
end
