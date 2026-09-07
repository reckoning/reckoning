# frozen_string_literal: true

module V1
  module Schemas
    # What the filtered set of invoices adds up to. Separate from the list
    # because paging cannot answer it: page two knows nothing about page one.
    class InvoiceSummary
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          count: {type: :integer},
          # Decimals cross the wire as strings.
          value: {type: :string},
          vat: {type: :string},
          # Every year the account has an invoice in, newest first. Not
          # filtered: it fills the year dropdown, so it has to offer the years
          # you could switch to.
          years: {type: :array, items: {type: :integer}}
        },
        additionalProperties: false,
        required: %w[count value vat years]
      })
    end
  end
end
