# frozen_string_literal: true

module V1
  module SecuritySchemes
    class SessionCookie
      include OpenapiRuby::Components::Base

      component_type :securitySchemes

      schema({
        type: :apiKey,
        in: :cookie,
        name: Rails.configuration.cookie_prefix,
        description: "Devise session cookie. Used by the web frontend."
      })
    end
  end
end
