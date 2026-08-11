# frozen_string_literal: true

json.id user.id
json.email user.email
json.name user.name
json.admin user.admin
json.enabled user.enabled
json.confirmed user.confirmed_at.present?
json.account_id user.account_id
json.created_at user.created_at
json.updated_at user.updated_at
