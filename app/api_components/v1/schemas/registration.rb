# frozen_string_literal: true

module V1
  module Schemas
    class Registration
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          plan: {type: [:string, :null]},
          createdAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name createdAt]
      })
    end
  end
end
