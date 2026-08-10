# frozen_string_literal: true

module V1
  module Schemas
    # Admin-facing view of a user: richer than the public User, and spans
    # every account rather than just the caller's.
    class BackendUser
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          email: {type: :string},
          name: {type: [:string, :null]},
          admin: {type: [:boolean, :null]},
          enabled: {type: [:boolean, :null]},
          confirmed: {type: :boolean},
          accountId: {type: :string, format: :uuid},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id email confirmed accountId createdAt updatedAt]
      })
    end
  end
end
