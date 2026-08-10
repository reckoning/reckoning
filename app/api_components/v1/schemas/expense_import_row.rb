# frozen_string_literal: true

module V1
  module Schemas
    # A parsed, unsaved row from the preview step.
    class ExpenseImportRow
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          date: {type: [:string, :null], format: :date},
          startedAt: {type: [:string, :null], format: :date},
          endedAt: {type: [:string, :null], format: :date},
          value: {type: [:string, :number, :null]},
          vatPercent: {type: [:integer, :null]},
          privateUsePercent: {type: [:integer, :null]},
          interval: {type: [:string, :null]},
          afaTypeId: {type: [:string, :null], format: :uuid},
          seller: {type: [:string, :null]},
          description: {type: [:string, :null]},
          expenseType: {type: [:string, :null]}
        },
        additionalProperties: false
      })
    end
  end
end
