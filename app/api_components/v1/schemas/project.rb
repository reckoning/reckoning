# frozen_string_literal: true

module V1
  module Schemas
    class Project
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          customerName: {type: [:string, :null]},
          label: {type: :string},
          customerId: {type: [:string, :null], format: :uuid},
          workflowState: {type: :string},
          # Decimal columns, returned as strings so no precision is lost on
          # the way through JSON.
          rate: {type: [:string, :null]},
          budget: {type: [:string, :null]},
          budgetHours: {type: [:string, :null]},
          budgetOnDashboard: {type: [:boolean, :null]},
          roundUp: {type: [:string, :null]},
          invoiceAddition: {type: [:string, :null]},
          startDate: {type: [:string, :null], format: "date-time"},
          endDate: {type: [:string, :null], format: "date-time"},
          # What the list shows next to the budget: hours booked, and how far
          # that has eaten into the budget. Both are model-derived, so the
          # client does not have to re-implement the arithmetic.
          timerValues: {type: :string},
          budgetPercent: {type: [:string, :null]},
          tasks: {type: :array, items: V1::Schemas::ProjectTask},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"},
          # Consumed by the AngularJS project service. Drops out in Phase B3,
          # together with the code that reads it.
          links: {
            type: :object,
            properties: {
              show: {type: :object, properties: {href: {type: :string}}, required: %w[href]}
            },
            additionalProperties: false
          }
        },
        additionalProperties: false,
        required: %w[id name workflowState tasks createdAt updatedAt]
      })
    end
  end
end
