# frozen_string_literal: true

module V1
  module Schemas
    # What the filtered set of expenses adds up to. Separate from the list
    # because paging cannot answer it: page two knows nothing about page one.
    class ExpenseSummary
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          count: {type: :integer},
          # Decimals cross the wire as strings.
          value: {type: :string},
          vat: {type: :string},
          # The years the year filter offers, newest first.
          years: {type: :array, items: {type: :integer}}
        },
        additionalProperties: false,
        required: %w[count value vat years]
      })
    end
  end
end
