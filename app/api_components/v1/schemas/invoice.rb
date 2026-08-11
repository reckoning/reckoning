# frozen_string_literal: true

module V1
  module Schemas
    class Invoice
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          ref: {type: [:integer, :null]},
          refNumber: {type: [:string, :null]},
          title: {type: [:string, :null]},
          state: {type: [:string, :null], enum: ["created", "charged", "paid", nil]},
          date: {type: [:string, :null], format: :date},
          deliveryDate: {type: [:string, :null], format: :date},
          paymentDueDate: {type: [:string, :null], format: :date},
          payDate: {type: [:string, :null], format: "date-time"},
          # Decimal columns cross the wire as strings.
          value: {type: [:string, :null]},
          vat: {type: [:string, :null]},
          customerId: {type: [:string, :null], format: :uuid},
          customerName: {type: [:string, :null]},
          projectId: {type: [:string, :null], format: :uuid},
          projectName: {type: [:string, :null]},
          editable: {type: :boolean, description: "False once the invoice has been charged."},
          sendable: {type: :boolean, description: "The customer has an invoice email and template."},
          positions: {type: :array, items: V1::Schemas::InvoicePosition},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id state positions editable sendable createdAt updatedAt]
      })
    end
  end
end
