# frozen_string_literal: true

json.rows @expenses do |expense|
  json.partial! "api/v1/expense_imports/row", expense: expense
end
