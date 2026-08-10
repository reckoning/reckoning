# frozen_string_literal: true

module V1
  module SecuritySchemes
    class BearerAuth
      include OpenapiRuby::Components::Base
      component_type :securitySchemes

      schema({
        type: :http,
        scheme: :bearer,
        bearerFormat: "JWT",
        description: "JWT from POST /sessions. Used by non-browser clients."
      })
    end
  end
end
