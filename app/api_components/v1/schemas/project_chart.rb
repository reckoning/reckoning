# frozen_string_literal: true

module V1
  module Schemas
    # What a project's budget chart is drawn from: the billable work booked
    # against it, added up week by week, against the budget it has.
    class ProjectChart
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          labels: {type: :array, items: {type: :string}, description: "The Monday of each week."},
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
                  description: "Index up to which the series is drawn solid; past it are the weeks that have not happened yet."
                }
              },
              additionalProperties: false,
              required: %w[name color data zone]
            }
          },
          # Decimals cross the wire as strings.
          budget: {type: [:string, :null], description: "Drawn as the line the work is measured against."},
          ticks: {
            type: :array,
            items: {type: :integer},
            description: "The weeks a month begins in, which is where the axis is labelled."
          }
        },
        additionalProperties: false,
        required: %w[labels datasets ticks]
      })
    end
  end
end
