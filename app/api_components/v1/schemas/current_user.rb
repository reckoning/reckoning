# frozen_string_literal: true

module V1
  module Schemas
    # The signed-in user's own record — richer than the admin-facing User,
    # which is what other people are allowed to see.
    class CurrentUser
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          email: {type: :string},
          name: {type: [:string, :null]},
          avatar: {type: [:string, :null], format: :uri},
          gravatar: {type: [:string, :null]},
          layout: {type: [:string, :null]},
          admin: {type: [:boolean, :null]},
          accountId: {type: :string, format: :uuid},
          otpRequired: {type: [:boolean, :null], description: "Two-factor authentication is enabled."},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id email accountId createdAt updatedAt]
      })
    end
  end
end
