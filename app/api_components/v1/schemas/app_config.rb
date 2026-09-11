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
          },
          version: {type: :string, description: "Reckoning::VERSION, which the footer prints."},
          codename: {type: :string, description: "Reckoning::CODENAME, which the footer prints."}
        },
        additionalProperties: false,
        required: %w[registrationEnabled domain version codename]
      })
    end
  end
end
