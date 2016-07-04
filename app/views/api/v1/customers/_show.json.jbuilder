# encoding: utf-8
# frozen_string_literal: true
json.uuid customer.uuid
json.name customer.name
json.created_at customer.created_at
json.updated_at customer.updated_at
json.links do
  json.show do
    json.href v1_customer_path(customer.id)
  end
end
