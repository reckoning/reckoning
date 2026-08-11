# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ProjectInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            customer_id: {type: :string, format: :uuid},
            name: {type: :string, minLength: 1},
            # Decimal columns; accepted as string or number, returned as string.
            rate: {type: [:string, :number]},
            budget: {type: [:string, :number]},
            budget_hours: {type: [:string, :number]},
            budget_on_dashboard: {type: :boolean},
            invoice_addition: {type: [:string, :null]},
            tasks_attributes: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  name: {type: :string},
                  billable: {type: :boolean},
                  _destroy: {type: :boolean}
                },
                additionalProperties: false
              }
            }
          },
          additionalProperties: false,
          required: %w[name]
        })
      end
    end
  end
end
