# frozen_string_literal: true

module V1
  module Schemas
    class Timer
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          date: {type: [:string, :null], format: :date},
          # Decimal columns serialise as strings, not numbers. The Vue island
          # types currently declare `number` for these — wrong, and worth
          # fixing when the timesheet moves onto the generated client (B4).
          value: {type: [:string, :null]},
          sumForTask: {type: [:string, :null]},
          note: {type: [:string, :null]},
          started: {type: :boolean},
          startedAt: {type: [:string, :null], format: "date-time"},
          startTime: {type: [:integer, :null], description: "Epoch milliseconds."},
          startTimeForTask: {type: [:integer, :null], description: "Epoch milliseconds."},
          positionId: {type: [:string, :null], format: :uuid},
          invoiced: {type: :boolean},
          taskId: {type: :string, format: :uuid},
          taskName: {type: :string},
          taskLabel: {type: :string},
          taskBillable: {type: :boolean},
          projectId: {type: :string, format: :uuid},
          projectName: {type: :string},
          projectCustomerName: {type: [:string, :null]},
          deleted: {type: :boolean},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"},
          # Consumed by the AngularJS timer service. Drops out in Phase B5,
          # together with the code that reads it.
          links: {
            type: :object,
            properties: {
              project: {type: :object, properties: {href: {type: :string}}, required: %w[href]}
            },
            additionalProperties: false
          }
        },
        additionalProperties: false,
        required: %w[id taskId started invoiced deleted createdAt updatedAt]
      })
    end
  end
end
