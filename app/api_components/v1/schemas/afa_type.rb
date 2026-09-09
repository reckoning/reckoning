# frozen_string_literal: true

module V1
  module Schemas
    # A depreciation class: how many years an asset of this kind is written
    # off over. A reference table, the same for every account.
    class AfaType
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          # Translated, so it arrives in the language the request asked for.
          name: {type: [:string, :null]},
          value: {type: [:integer, :null], description: "Years the asset is written off over."}
        },
        additionalProperties: false,
        required: %w[id]
      })
    end
  end
end
