# frozen_string_literal: true

module V1
  module Schemas
    class ValidationError
      include OpenapiRuby::Components::Base

      # `errors` mirrors ActiveModel::Errors#as_json — attribute name to list of
      # messages. Absent when the failure isn't attribute-level (see
      # `::ValidationError`, which only sets it when errors are present).
      schema({
        type: :object,
        properties: {
          code: {type: :string},
          message: {type: :string},
          errors: {
            type: :object,
            additionalProperties: {
              type: :array,
              items: {type: :string}
            }
          }
        },
        additionalProperties: false,
        required: %w[code message]
      })
    end
  end
end
