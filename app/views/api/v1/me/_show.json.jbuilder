# frozen_string_literal: true

json.id user.id
json.email user.email
json.name user.name
json.avatar user.avatar(48)
json.gravatar user.gravatar
json.layout user.layout
json.admin user.admin
json.account_id user.account_id
json.otp_required user.otp_required_for_login
json.created_at user.created_at
json.updated_at user.updated_at
