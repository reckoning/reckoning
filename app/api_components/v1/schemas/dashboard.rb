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
          openInvoicesCount: {type: :integer},
          # Both null unless the account carries a provision rate.
          provision: {type: [:number, :string, :null]},
          lastYearProvision: {type: [:number, :string, :null]},
          # The hours behind the overtime panel: this week, today, and what
          # each employed customer is ahead or behind by.
          overtime: {
            type: :object,
            properties: {
              weeklyHours: {type: [:number, :string, :null]},
              dailyHours: {type: [:number, :string, :null]},
              customers: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    name: {type: [:string, :null]},
                    hours: {type: [:number, :string, :null]},
                    weeklyHours: {type: [:number, :string, :null]}
                  },
                  additionalProperties: false,
                  required: %w[name hours weeklyHours]
                }
              }
            },
            additionalProperties: false,
            required: %w[weeklyHours dailyHours customers]
          },
          # This year and the last, each as a running total and as sums per
          # month. Summed here because deriving them would mean shipping two
          # years of invoices to the client.
          chart: {
            type: :object,
            properties: {
              labels: {type: :array, items: {type: :string}},
              datasets: {
                type: :array,
                items: {
                  type: :object,
                  properties: {
                    name: {type: [:string, :null]},
                    color: {type: [:string, :null]},
                    data: {type: :array, items: {type: [:number, :string]}},
                    zone: {
                      type: [:integer, :null],
                      description: "Index up to which the series is drawn solid; the rest is the year that has not happened yet."
                    }
                  },
                  additionalProperties: false,
                  required: %w[name color data zone]
                }
              }
            },
            additionalProperties: false,
            required: %w[labels datasets]
          }
        },
        additionalProperties: false,
        required: %w[year openInvoicesCount overtime chart]
      })
    end
  end
end
