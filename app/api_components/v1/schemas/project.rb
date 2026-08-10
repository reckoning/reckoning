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
        required: %w[id name tasks createdAt updatedAt]
      })
    end
  end
end
