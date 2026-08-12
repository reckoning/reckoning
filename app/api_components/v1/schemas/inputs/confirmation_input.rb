# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ConfirmationInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            confirmation_token: {type: :string, description: "From the confirmation email."}
          },
          additionalProperties: false,
          required: %w[confirmation_token]
        })
      end
    end
  end
end
