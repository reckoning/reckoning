# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      # What an update takes. Creating also needs the first user's address,
      # which `BackendAccountCreateInput` requires — sharing one schema would
      # mean either an update that demands an email or a create that does not.
      class BackendAccountInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string},
            plan: {type: :string},
            feature_expenses: {type: :boolean},
            feature_logbook: {type: :boolean}
          },
          additionalProperties: false
        })
      end
    end
  end
end
