# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PasswordResetInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            reset_password_token: {type: :string, description: "From the reset email."},
            password: {type: :string, minLength: 8},
            password_confirmation: {type: :string}
          },
          additionalProperties: false,
          required: %w[reset_password_token password]
        })
      end
    end
  end
end
