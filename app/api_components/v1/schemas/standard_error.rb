# frozen_string_literal: true

module V1
  module Schemas
    class StandardError
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          code: {type: :string},
          message: {type: :string}
        },
        additionalProperties: false,
        required: %w[message]
      })
    end
  end
end
