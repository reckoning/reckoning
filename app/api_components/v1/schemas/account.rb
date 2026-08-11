# frozen_string_literal: true

module V1
  module Schemas
    class Account
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          name: {type: [:string, :null]},
          subdomain: {type: [:string, :null]},
          plan: {type: [:string, :null]},
          vatId: {type: [:string, :null]},
          tax: {type: [:string, :null], description: "Default tax rate, stored as a string."},
          provision: {type: [:string, :null]},
          bank: {type: [:string, :null]},
          accountNumber: {type: [:string, :null]},
          bankCode: {type: [:string, :null]},
          iban: {type: [:string, :null]},
          bic: {type: [:string, :null]},
          defaultFrom: {type: [:string, :null]},
          signature: {type: [:string, :null]},
          address: {type: [:string, :null]},
          country: {type: [:string, :null]},
          publicEmail: {type: [:string, :null]},
          telefon: {type: [:string, :null]},
          fax: {type: [:string, :null]},
          website: {type: [:string, :null]},
          officeSpace: {type: [:integer, :null]},
          deductibleOfficeSpace: {type: [:integer, :null]},
          offerHeadline: {type: [:string, :null]},
          featureExpenses: {type: [:boolean, :null]},
          featureLogbook: {type: [:boolean, :null]},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id createdAt updatedAt]
      })
    end
  end
end
