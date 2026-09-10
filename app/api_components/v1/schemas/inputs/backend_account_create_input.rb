# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # `email` is the first user the account gets: an account is invalid
      # without one, so creating takes both or neither.
      class BackendAccountCreateInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            email: {type: :string},
            plan: {type: :string},
            feature_expenses: {type: :boolean},
            feature_logbook: {type: :boolean}
          },
          additionalProperties: false,
          required: %w[name email]
        })
      end
    end
  end
end
