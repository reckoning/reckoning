# frozen_string_literal: true

module V1
  module Schemas
    class Expense
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          expenseType: {type: :string},
          description: {type: [:string, :null]},
          seller: {type: [:string, :null]},
          date: {type: [:string, :null], format: :date},
          # Decimal columns cross the wire as strings.
          value: {type: [:string, :null]},
          vatPercent: {type: [:integer, :null]},
          vatValue: {type: [:string, :null]},
          privateUsePercent: {type: [:integer, :null]},
          interval: {type: [:string, :null], description: "once, monthly, quarterly, yearly."},
          startedAt: {type: [:string, :null], format: :date},
          endedAt: {type: [:string, :null], format: :date},
          afaTypeId: {type: [:string, :null], format: :uuid},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id expenseType createdAt updatedAt]
      })
    end
  end
end
