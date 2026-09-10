# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class BackendAccountInput
        include OpenapiRuby::Components::Base

        # `email` is the first user the account gets, which is how the backend
        # creates one — the account is invalid without a user. It is ignored on
        # an update, where the users are managed on their own screen.
        schema({
          type: :object,
          properties: {
            name: {type: :string},
            email: {type: :string},
            plan: {type: :string},
            feature_expenses: {type: :boolean},
            feature_logbook: {type: :boolean}
          },
          additionalProperties: false
        })
      end
    end
  end
end
