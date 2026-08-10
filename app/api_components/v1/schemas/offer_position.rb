# frozen_string_literal: true

module V1
  module Schemas
    class OfferPosition
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          description: {type: [:string, :null]},
          hours: {type: [:string, :null]},
          rate: {type: [:string, :null]},
          value: {type: [:string, :null]},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id createdAt updatedAt]
      })
    end
  end
end
