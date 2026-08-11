# frozen_string_literal: true

module V1
  module Schemas
    class InvoicePosition
      include OpenapiRuby::Components::Base

      # A position is priced either as hours x rate, or as a flat value.
      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          description: {type: [:string, :null]},
          hours: {type: [:string, :null]},
          rate: {type: [:string, :null]},
          value: {type: [:string, :null]},
          timerIds: {type: :array, items: {type: :string, format: :uuid}},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id timerIds createdAt updatedAt]
      })
    end
  end
end
