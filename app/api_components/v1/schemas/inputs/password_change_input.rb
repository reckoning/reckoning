# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class PasswordChangeInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            current_password: {type: :string},
            password: {type: :string, minLength: 8},
            password_confirmation: {type: :string}
          },
          additionalProperties: false,
          required: %w[current_password password]
        })
      end
    end
  end
end
