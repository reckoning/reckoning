# frozen_string_literal: true

module V1
  module Schemas
    class Customer
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: :string},
          address: {type: [:string, :null]},
          country: {type: [:string, :null]},
          email: {type: [:string, :null]},
          telefon: {type: [:string, :null]},
          fax: {type: [:string, :null]},
          website: {type: [:string, :null]},
          paymentDue: {type: [:integer, :null]},
          invoiceEmail: {type: [:string, :null]},
          invoiceEmailCc: {type: [:string, :null]},
          invoiceEmailBcc: {type: [:string, :null]},
          defaultFrom: {type: [:string, :null]},
          emailTemplate: {type: [:string, :null]},
          offerDisclaimer: {type: [:string, :null]},
          employmentDate: {type: [:string, :null], format: :date},
          employmentEndDate: {type: [:string, :null], format: :date},
          weeklyHours: {type: [:integer, :null]},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id name createdAt updatedAt]
      })
    end
  end
end
