# frozen_string_literal: true

json.partial! partial: 'api/v1/vessels/show', collection: @vessels, as: :vessel
