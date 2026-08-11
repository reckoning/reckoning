# frozen_string_literal: true

json.registration_enabled Rails.configuration.app.registration
json.account_name current_account&.name
