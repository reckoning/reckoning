# frozen_string_literal: true

Appsignal.configure do |config|
  config.name = "Reckoning"

  # Credentials are the primary home, mirroring the rest of the app's secrets.
  # The env var is what Kamal injects, and is also the name AppSignal reads by
  # default — spelling it out keeps `active` below in step with either source.
  push_api_key = Rails.application.credentials.appsignal_push_api_key.presence ||
    ENV["APPSIGNAL_PUSH_API_KEY"].presence
  config.push_api_key = push_api_key if push_api_key

  # Without a key the agent has nowhere to report to, so staying inactive keeps
  # development and test quiet without needing a per-environment switch.
  config.active = push_api_key.present?

  config.revision = Git.revision_short if Git.revision_short.present?
  config.default_tags = {version: Reckoning::VERSION, codename: Reckoning::CODENAME}

  # AppSignal does not pick up Rails' filter_parameters on its own, and
  # `send_params` defaults to true — without this, passwords and OTPs would ride
  # along in every reported request.
  config.filter_parameters = Rails.application.config.filter_parameters
    .select { |filter| filter.is_a?(Symbol) || filter.is_a?(String) }
    .map(&:to_s)
end
