# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ProjectInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            # The ERB select offered a blank option, so a project can be left
            # without a customer — and an existing one can be cleared.
            customer_id: {type: [:string, :null], format: :uuid},
            name: {type: :string, minLength: 1},
            # Decimal columns; accepted as string or number, returned as string.
            rate: {type: [:string, :number]},
            budget: {type: [:string, :number]},
            budget_hours: {type: [:string, :number]},
            budget_on_dashboard: {type: :boolean},
            # Timer rounding. The ERB form set it from
            # `Project::DEFAULT_ROUND_UP_OPTIONS`.
            round_up: {type: [:string, :number]},
            invoice_addition: {type: [:string, :null]},
            start_date: {type: [:string, :null], format: "date-time"},
            end_date: {type: [:string, :null], format: "date-time"},
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
