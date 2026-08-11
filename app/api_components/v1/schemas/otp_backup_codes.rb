# frozen_string_literal: true

module V1
  module Schemas
    class OtpBackupCodes
      include OpenapiRuby::Components::Base

      # Shown once. Generating a new set invalidates the previous one.
      schema({
        type: :object,
        properties: {
          otpRequired: {type: [:boolean, :null]},
          backupCodes: {type: :array, items: {type: :string}}
        },
        additionalProperties: false,
        required: %w[backupCodes]
      })
    end
  end
end
