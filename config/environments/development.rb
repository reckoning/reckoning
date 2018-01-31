# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.action_controller.default_url_options = { host: Rails.application.secrets[:domain] }

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  config.action_mailer.perform_deliveries = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { host: Rails.application.secrets[:domain] }
  config.action_mailer.smtp_settings = {
    address: Rails.application.secrets[:mailer_host],
    port: Rails.application.secrets[:mailer_port],
    enable_starttls_auto: true,
    user_name: Rails.application.secrets[:mailer_user],
    password: Rails.application.secrets[:mailer_password],
    authentication: 'login',
    domain: Rails.application.secrets[:domain]
  }

  config.action_cable.allowed_request_origins = ['http://reckoning.dev', 'http://localhost:8240', 'http://0.0.0.0:8240']

  config.after_initialize do
    Bullet.enable = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end
end
