# frozen_string_literal: true

json.columns @columns do |column|
  json.name column.name
  json.type column.type
end
