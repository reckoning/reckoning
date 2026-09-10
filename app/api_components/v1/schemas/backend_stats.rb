# frozen_string_literal: true

module V1
  module Schemas
    # The numbers the backend dashboard prints beside its lists.
    class BackendStats
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          usersCount: {type: :integer},
          accountsCount: {type: :integer}
        },
        additionalProperties: false,
        required: %w[usersCount accountsCount]
      })
    end
  end
end
