require 'raven'

Raven.configure(true) do |config|
  config.dsn = Rails.application.secrets[:sentry]
  config.environments = %w[ production ]
end
