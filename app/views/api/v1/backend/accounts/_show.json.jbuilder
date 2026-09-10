# frozen_string_literal: true

json.id account.id
json.name account.name
json.subdomain account.subdomain
json.plan account.plan
json.feature_expenses account.feature_expenses?
json.feature_logbook account.feature_logbook?
json.users_count account.users.size
json.trial_end_at account.trial_end_at
json.created_at account.created_at
json.updated_at account.updated_at
