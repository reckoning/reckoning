# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class UnlockInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            unlock_token: {type: :string, description: "From the unlock email."}
          },
          additionalProperties: false,
          required: %w[unlock_token]
        })
      end
    end
  end
end
