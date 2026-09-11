# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class RegistrationInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, minLength: 1},
            plan: {type: :string},
            vat_id: {type: [:string, :null]},
            # Where the account answers, if it wants one of its own. Optional:
            # most accounts live on the apex host.
            subdomain: {type: [:string, :null]},
            users_attributes: {
              type: :array,
              minItems: 1,
              items: {
                type: :object,
                properties: {
                  email: {type: :string},
                  password: {type: :string, minLength: 8},
                  password_confirmation: {type: :string}
                },
                additionalProperties: false,
                required: %w[email password]
              }
            }
          },
          additionalProperties: false,
          required: %w[name plan users_attributes]
        })
      end
    end
  end
end
