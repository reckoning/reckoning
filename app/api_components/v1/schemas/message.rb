# frozen_string_literal: true

module V1
  module Schemas
    class Message
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          message: {type: :string}
        },
        additionalProperties: false,
        required: %w[message]
      })
    end
  end
end
