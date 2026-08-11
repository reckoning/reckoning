# frozen_string_literal: true

module V1
  module Schemas
    class User
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          email: {type: :string},
          name: {type: [:string, :null]},
          avatar: {type: [:string, :null], format: :uri},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id email createdAt updatedAt]
      })
    end
  end
end
