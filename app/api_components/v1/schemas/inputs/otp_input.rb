# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class OtpInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            otp_attempt: {type: :string, description: "Current code from the authenticator app."}
          },
          additionalProperties: false,
          required: %w[otp_attempt]
        })
      end
    end
  end
end
