# frozen_string_literal: true

module V1
  module Schemas
    class Dashboard
      include OpenapiRuby::Components::Base

      # Money values are computed sums rather than columns, so they arrive as
      # JSON numbers here — unlike the decimal *columns* elsewhere in the API,
      # which serialise as strings.
      schema({
        type: :object,
        properties: {
          year: {type: :integer},
          uninvoicedAmount: {type: [:number, :string, :null]},
          chargedSum: {type: [:number, :string, :null]},
          paidSum: {type: [:number, :string, :null]},
          lastYearPaidSum: {type: [:number, :string, :null]},
          expensesSum: {type: [:number, :string, :null]},
          lastYearExpensesSum: {type: [:number, :string, :null]},
          openInvoicesCount: {type: :integer}
        },
        additionalProperties: false,
        required: %w[year openInvoicesCount]
      })
    end
  end
end
