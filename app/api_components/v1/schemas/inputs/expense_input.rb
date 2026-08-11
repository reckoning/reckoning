# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ExpenseInput
        include OpenapiRuby::Components::Base

        # `receipt` is a file and is uploaded separately, not through this
        # JSON body.
        schema({
          type: :object,
          properties: {
            expense_type: {type: :string},
            afa_type_id: {type: [:string, :null], format: :uuid},
            description: {type: [:string, :null]},
            seller: {type: [:string, :null]},
            date: {type: [:string, :null], format: :date},
            value: {type: [:string, :number, :null]},
            private_use_percent: {type: [:integer, :null]},
            vat_percent: {type: [:integer, :null]},
            interval: {type: [:string, :null]},
            started_at: {type: [:string, :null], format: :date},
            ended_at: {type: [:string, :null], format: :date}
          },
          additionalProperties: false
        })
      end
    end
  end
end
