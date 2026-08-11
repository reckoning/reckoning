# frozen_string_literal: true

json.partial! partial: "api/v1/expenses/show", collection: @expenses, as: :expense
