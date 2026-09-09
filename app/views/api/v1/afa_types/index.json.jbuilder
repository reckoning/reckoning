# frozen_string_literal: true

json.array! @afa_types do |afa_type|
  json.id afa_type.id
  json.name afa_type.name
  json.value afa_type.value
end
