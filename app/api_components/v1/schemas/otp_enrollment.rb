# frozen_string_literal: true

module V1
  module Schemas
    class OtpEnrollment
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          otpRequired: {type: [:boolean, :null]},
          provisioningUri: {
            type: :string,
            description: "otpauth:// URI for an authenticator app. Also available as SVG from /me/otp/qrcode."
          }
        },
        additionalProperties: false,
        required: %w[provisioningUri]
      })
    end
  end
end
