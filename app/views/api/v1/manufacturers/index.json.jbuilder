# frozen_string_literal: true

json.partial! partial: 'api/v1/manufacturers/show', collection: @manufacturers, as: :manufacturer
