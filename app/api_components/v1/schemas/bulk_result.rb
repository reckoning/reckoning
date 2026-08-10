# frozen_string_literal: true

module V1
  module Schemas
    class BulkResult
      include OpenapiRuby::Components::Base

      # `count` is how many records actually changed, which can be fewer than
      # the ids sent if some failed validation.
      schema({
        type: :object,
        properties: {
          count: {type: :integer},
          message: {type: :string}
        },
        additionalProperties: false,
        required: %w[count message]
      })
    end
  end
end
