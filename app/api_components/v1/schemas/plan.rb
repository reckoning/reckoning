# frozen_string_literal: true

module V1
  module Schemas
    # What the welcome page prices. Public: the page that reads it is the one
    # visitors see before they have an account.
    class Plan
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          code: {type: :string},
          name: {type: :string},
          price: {type: :integer, description: "In cents, discount already applied."},
          quantity: {type: [:integer, :null]},
          interval: {type: [:string, :null], description: "`month` or `year`."},
          featured: {type: [:boolean, :null]},
          descriptions: {
            type: :array,
            items: {type: :string},
            description: "What the plan includes, one line each, as the locale authored them."
          }
        },
        additionalProperties: false,
        required: %w[id code name price descriptions]
      })
    end
  end
end
