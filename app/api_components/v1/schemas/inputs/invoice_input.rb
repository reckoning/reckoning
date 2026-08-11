# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class InvoiceInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            project_id: {type: :string, format: :uuid},
            customer_id: {type: :string, format: :uuid},
            ref: {type: [:integer, :null]},
            date: {type: [:string, :null], format: :date},
            delivery_date: {type: [:string, :null], format: :date},
            payment_due_date: {type: [:string, :null], format: :date},
            positions_attributes: {
              type: :array,
              items: {
                type: :object,
                properties: {
                  id: {type: :string, format: :uuid},
                  description: {type: [:string, :null]},
                  hours: {type: [:string, :number, :null]},
                  rate: {type: [:string, :number, :null]},
                  value: {type: [:string, :number, :null]},
                  timer_ids: {type: :array, items: {type: :string, format: :uuid}},
                  _destroy: {type: :boolean}
                },
                additionalProperties: false
              }
            }
          },
          additionalProperties: false
        })
      end
    end
  end
end
