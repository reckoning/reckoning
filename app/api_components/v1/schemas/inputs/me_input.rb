# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class MeInput
        include OpenapiRuby::Components::Base

        # Profile fields only. Changing the password or email confirmation
        # goes through Devise, not here.
        schema({
          type: :object,
          properties: {
            email: {type: :string},
            name: {type: [:string, :null]},
            gravatar: {type: [:string, :null]},
            layout: {type: :string}
          },
          additionalProperties: false
        })
      end
    end
  end
end
