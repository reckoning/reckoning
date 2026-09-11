# frozen_string_literal: true

json.registration_enabled Rails.configuration.app.registration
json.account_name current_account&.name
# What a subdomain sits under, which the account settings print after the
# field: the host in the browser cannot be taken apart for it — on an apex
# host like `reckoning.test` the first label *is* the app.
json.domain Rails.configuration.app.domain

# The footer names the release, the way `layouts/_footer` did.
json.version Reckoning::VERSION
json.codename Reckoning::CODENAME
