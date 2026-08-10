# frozen_string_literal: true

module V1
  module Schemas
    class ExpenseImportPreview
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          rows: {type: :array, items: V1::Schemas::ExpenseImportRow}
        },
        additionalProperties: false,
        required: %w[rows]
      })
    end
  end
end
