# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ExpenseBulkDestroyInput
        include OpenapiRuby::Components::Base

        # Separate from ExpenseBulkInput: destroy reads only the ids, so
        # advertising the bulk edit bar's attribute fields here would document
        # parameters the action ignores.
        schema({
          type: :object,
          properties: {
            expenseIds: {type: :array, items: {type: :string, format: :uuid}}
          },
          additionalProperties: false,
          required: %w[expenseIds]
        })
      end
    end
  end
end
