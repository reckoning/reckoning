# frozen_string_literal: true

module V1
  module Schemas
    class Offer
      include OpenapiRuby::Components::Base

      schema({
        type: :object,
        properties: {
          id: {type: :string, format: :uuid},
          ref: {type: [:integer, :null]},
          refNumber: {type: [:string, :null]},
          title: {type: [:string, :null]},
          state: {type: [:string, :null], enum: ["created", "bided", "accepted", "declined", "canceled", nil]},
          date: {type: [:string, :null], format: :date},
          description: {type: [:string, :null]},
          value: {type: [:string, :null]},
          rate: {type: [:string, :null]},
          customerId: {type: [:string, :null], format: :uuid},
          customerName: {type: [:string, :null]},
          projectId: {type: [:string, :null], format: :uuid},
          projectName: {type: [:string, :null]},
          editable: {type: :boolean, description: "False once bided or accepted. Says nothing about permissions — see abilities.update."},
          # What this user may do with this offer, model state and the user's
          # own abilities together. An expired trial reads everything and
          # writes nothing, which no model-level flag says.
          abilities: {
            type: :object,
            properties: {
              update: {type: :boolean},
              destroy: {type: :boolean},
              transitions: {
                type: :array,
                items: {type: :string, enum: %w[bid accept decline cancel]},
                description: "Events the offer can be moved along by right now."
              }
            },
            additionalProperties: false,
            required: %w[update destroy transitions]
          },
          positions: {type: :array, items: V1::Schemas::OfferPosition},
          createdAt: {type: :string, format: "date-time"},
          updatedAt: {type: :string, format: "date-time"}
        },
        additionalProperties: false,
        required: %w[id state positions editable abilities createdAt updatedAt]
      })
    end
  end
end
