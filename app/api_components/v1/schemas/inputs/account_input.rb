# frozen_string_literal: true

module V1
  module Schemas
    module Inputs
      class AccountInput
        include OpenapiRuby::Components::Base

        # Mirrors the settings form. `plan`, `stripeEmail` and `stripeToken`
        # are deliberately absent: billing changes go through the Stripe flow,
        # not a profile update.
        schema({
          type: :object,
          properties: {
            name: {type: [:string, :null]},
            subdomain: {type: [:string, :null]},
            vatId: {type: [:string, :null]},
            tax: {type: [:string, :null]},
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
            offerHeadline: {type: [:string, :null]}
          },
          additionalProperties: false
        })
      end
    end
  end
end
