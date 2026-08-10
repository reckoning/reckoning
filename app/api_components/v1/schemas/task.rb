# frozen_string_literal: true

module V1
  module Schemas
    class Task
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          label: {type: :string},
          billable: {type: :boolean},
          projectId: {type: :string, format: :uuid},
          projectName: {type: :string},
          projectCustomerName: {type: [:string, :null]},
          timers: {type: :array, items: V1::Schemas::TaskTimer},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name projectId timers createdAt updatedAt]
      })
    end
  end
end
