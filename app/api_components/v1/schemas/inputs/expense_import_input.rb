# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ExpenseImportInput
        include OpenapiRuby::Components::Base

        # The rows kept from the preview, after any edits. `include` is what
        # the checkbox column sets; rows without it are ignored.
        schema({
          type: :object,
          properties: {
            rows: {
              type: :array,
              minItems: 1,
              items: {
                type: :object,
                properties: {
                  include: {type: [:boolean, :string]},
                  date: {type: [:string, :null], format: :date},
                  started_at: {type: [:string, :null], format: :date},
                  ended_at: {type: [:string, :null], format: :date},
                  value: {type: [:string, :number, :null]},
                  vat_percent: {type: [:integer, :string, :null]},
                  private_use_percent: {type: [:integer, :string, :null]},
                  interval: {type: [:string, :null]},
                  afa_type_id: {type: [:string, :null], format: :uuid},
                  seller: {type: [:string, :null]},
                  description: {type: [:string, :null]},
                  expense_type: {type: [:string, :null]}
                },
                additionalProperties: false
              }
            }
          },
          additionalProperties: false,
          required: %w[rows]
        })
      end
    end
  end
end
