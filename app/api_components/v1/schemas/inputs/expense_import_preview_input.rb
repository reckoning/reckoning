# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ExpenseImportPreviewInput
        include OpenapiRuby::Components::Base

        # Multipart: the remaining fields are defaults stamped onto every
        # parsed row before the user edits them.
        schema({
          type: :object,
          properties: {
            file: {type: :string, format: :binary},
            expense_type: {type: :string},
            vat_percent: {type: [:integer, :string]},
            private_use_percent: {type: [:integer, :string]},
            interval: {type: :string},
            skip_credits: {type: [:boolean, :string], description: "Skip incoming payments."}
          },
          required: %w[file]
        })
      end
    end
  end
end
