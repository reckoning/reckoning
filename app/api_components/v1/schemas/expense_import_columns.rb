# frozen_string_literal: true

module V1
  module Schemas
    # The columns an exported CSV carries, which is what an imported one may
    # carry too.
    class ExpenseImportColumns
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          columns: {
            type: :array,
            items: {
              type: :object,
              properties: {
                name: {type: :string},
                type: {type: :string, description: "The column's type, as the database has it."}
              },
              additionalProperties: false,
              required: %w[name type]
            }
          }
        },
        additionalProperties: false,
        required: %w[columns]
      })
    end
  end
end
