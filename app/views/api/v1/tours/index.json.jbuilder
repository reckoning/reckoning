# frozen_string_literal: true

json.partial! partial: 'api/v1/tours/show', collection: @tours, as: :tour
