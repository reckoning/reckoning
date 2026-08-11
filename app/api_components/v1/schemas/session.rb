# frozen_string_literal: true

module V1
  module Schemas
    class Session
      include OpenapiRuby::Components::Base

      # Rendered by `render json:` rather than jbuilder, so this key is not
      # camelized like the rest of the API.
      schema({
        type: :object,
        properties: {
          auth_token: {type: :string, description: "JWT for the Authorization header."}
        },
        additionalProperties: false,
        required: %w[auth_token]
      })
    end
  end
end
