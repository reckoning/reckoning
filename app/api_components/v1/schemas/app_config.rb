# frozen_string_literal: true

module V1
  module Schemas
    class AppConfig
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          registrationEnabled: {
            type: :boolean,
            description: "Whether signup is offered. Mirrors Rails.configuration.app.registration."
          },
          accountName: {
            type: [:string, :null],
            description: "Name of the account the subdomain resolves to, if any."
          },
          domain: {
            type: :string,
            description: "The host an account's subdomain sits under. Mirrors Rails.configuration.app.domain."
          }
        },
        additionalProperties: false,
        required: %w[registrationEnabled domain]
      })
    end
  end
end
