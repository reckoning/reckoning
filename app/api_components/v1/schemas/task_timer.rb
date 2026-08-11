# frozen_string_literal: true

module V1
  module Schemas
    # A timer as nested inside a task payload — narrower than the standalone
    # Timer, which also carries denormalised task and project fields.
    class TaskTimer
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          taskId: {type: :string, format: :uuid},
          date: {type: [:string, :null], format: :date},
          # Decimal columns serialise as strings, not numbers.
          value: {type: [:string, :null]},
          sumForTask: {type: [:string, :null]},
          note: {type: [:string, :null]},
          started: {type: :boolean},
          startedAt: {type: [:string, :null], format: "date-time"},
          startTime: {type: [:integer, :null], description: "Epoch milliseconds."},
          startTimeForTask: {type: [:integer, :null], description: "Epoch milliseconds."},
          positionId: {type: [:string, :null], format: :uuid},
          invoiced: {type: :boolean},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id taskId started invoiced createdAt updatedAt]
      })
    end
  end
end
