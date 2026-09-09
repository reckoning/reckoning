# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class ExpenseReceiptInput
        include OpenapiRuby::Components::Base

        # Multipart: the receipt is a pdf or an image of one.
        schema({
          type: :object,
          properties: {
            receipt: {type: :string, format: :binary}
          },
          required: %w[receipt]
        })
      end
    end
  end
end
