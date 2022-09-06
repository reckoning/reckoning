# frozen_string_literal: true

Sentry.init do |config|
  config.dsn = Rails.application.credentials.sentry_dsn
  config.release = Git.revision_short
  config.tags = {
    version: Reckoning::VERSION,
    codename: Reckoning::CODENAME
  }
end
