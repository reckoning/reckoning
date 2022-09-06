# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn
  config.release = Git.revision_short
end

Sentry.set_tags(version: Reckoning::VERSION)
Sentry.set_tags(codename: Reckoning::CODENAME)
