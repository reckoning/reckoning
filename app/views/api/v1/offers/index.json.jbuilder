# frozen_string_literal: true

json.partial! partial: "api/v1/offers/show", collection: @offers, as: :offer
