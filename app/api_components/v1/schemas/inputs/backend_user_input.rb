# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class BackendUserInput
        include OpenapiRuby::Components::Base

        # No password: the admin flow mails a confirmation and the user sets
        # their own. `admin` is settable here because the whole namespace is
        # already admin-only.
        schema({
          type: :object,
          properties: {
            email: {type: :string},
            name: {type: [:string, :null]},
            admin: {type: :boolean},
            enabled: {type: :boolean},
            account_id: {type: :string, format: :uuid}
          },
          additionalProperties: false
        })
      end
    end
  end
end
