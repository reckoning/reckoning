# frozen_string_literal: true

module V1
  module Schemas
    # Admin-facing view of an account: what the backend list and form show,
    # which is the plan, the feature flags and who is on it.
    class BackendAccount
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          subdomain: {type: [:string, :null]},
          # The column is nullable — the presence validation covers what goes
          # in through the app, not a row that predates it.
          plan: {type: [:string, :null]},
          featureExpenses: {type: :boolean},
          featureLogbook: {type: :boolean},
          usersCount: {type: :integer},
          trialEndAt: {type: [:string, :null], format: "date-time"},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name plan featureExpenses featureLogbook usersCount createdAt updatedAt]
      })
    end
  end
end
