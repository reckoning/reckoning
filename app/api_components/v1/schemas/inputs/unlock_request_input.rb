# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class UnlockRequestInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            email: {type: :string}
          },
          additionalProperties: false,
          required: %w[email]
        })
      end
    end
  end
end
