# frozen_string_literal: true

require File.expand_path('boot', __dir__)

require 'rails/all'
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Reckoning
  class Application < Rails::Application
    config.autoload_paths << Rails.root.join('lib')

    config.load_defaults 6.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'

    # The default locale is :de and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = :de
    config.i18n.load_path += Dir[Rails.root.join('config/locales/**/*.{rb,yml}').to_s]

    config.i18n.fallbacks = [:de]

    config.action_view.field_error_proc = proc { |html_tag, _instance|
      # rubocop:disable Rails/OutputSafety
      html_tag.to_s.html_safe
      # rubocop:enable Rails/OutputSafety
    }

    config.exceptions_app = routes

    config.middleware.use I18n::JS::Middleware
  end
end

I18n.config.enforce_available_locales = true

require_relative 'version'
