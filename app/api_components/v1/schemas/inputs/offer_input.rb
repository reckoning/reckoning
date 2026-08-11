# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class OfferInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            project_id: {type: :string, format: :uuid},
            customer_id: {type: :string, format: :uuid},
            ref: {type: [:integer, :null]},
            date: {type: [:string, :null], format: :date},
            description: {type: [:string, :null]},
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
