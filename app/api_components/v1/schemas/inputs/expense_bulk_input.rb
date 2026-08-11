# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ExpenseBulkInput
        include OpenapiRuby::Components::Base

        # Only the fields the bulk edit bar offers. Blank values are ignored
        # rather than written, so a partially filled bar leaves the rest alone.
        schema({
          type: :object,
          properties: {
            expenseIds: {type: :array, items: {type: :string, format: :uuid}},
            expense_type: {type: [:string, :null]},
            vat_percent: {type: [:integer, :null]},
            private_use_percent: {type: [:integer, :null]}
          },
          additionalProperties: false,
          required: %w[expenseIds]
        })
      end
    end
  end
end
