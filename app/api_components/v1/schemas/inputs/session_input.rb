# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class SessionInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            email: {type: :string},
            password: {type: :string},
            otp_token: {type: :string, description: "Required when the account has 2FA enabled. Takes a TOTP code or one of the account's backup codes."},
            remember_me: {type: :boolean, description: "Issue a persistent cookie. Ignored by token clients."},
            description: {type: :string, description: "Labels the token in the account's token list."},
            expires: {type: :string, format: "date-time"}
          },
          additionalProperties: false,
          required: %w[email password]
        })
      end
    end
  end
end
