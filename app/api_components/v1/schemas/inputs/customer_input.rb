# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class CustomerInput
        include OpenapiRuby::Components::Base

        schema({
          type: :object,
          properties: {
            name: {type: :string, minLength: 1},
            address: {type: :string},
            country: {type: :string},
            email: {type: :string},
            telefon: {type: :string},
            fax: {type: :string},
            website: {type: :string},
            paymentDue: {type: :integer},
            invoiceEmail: {type: :string},
            invoiceEmailCc: {type: :string},
            invoiceEmailBcc: {type: :string},
            defaultFrom: {type: :string},
            emailTemplate: {type: :string},
            offerDisclaimer: {type: :string},
            employmentDate: {type: :string, format: :date},
            employmentEndDate: {type: :string, format: :date},
            weeklyHours: {type: :integer}
          },
          additionalProperties: false,
          required: %w[name]
        })
      end
    end
  end
end
