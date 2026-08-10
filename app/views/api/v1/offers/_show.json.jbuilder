# frozen_string_literal: true

json.id offer.id
json.ref offer.ref
json.ref_number offer.ref_number
json.title offer.title
json.state offer.aasm_state
json.date offer.date
json.description offer.description
json.value offer.value
json.rate offer.rate
json.customer_id offer.customer_id
json.customer_name offer.customer&.name
json.project_id offer.project_id
json.project_name offer.project&.name
json.editable offer.editable?
json.positions offer.positions.order(:created_at) do |position|
  json.partial! "api/v1/offers/position", position: position
end
json.created_at offer.created_at
json.updated_at offer.updated_at
