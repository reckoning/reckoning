# frozen_string_literal: true

json.id customer.id
json.name customer.name
json.created_at customer.created_at
json.updated_at customer.updated_at
json.links do
  json.show do
    json.href api_v1_customer_path(customer.id)
  end
end
