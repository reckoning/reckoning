# encoding: utf-8
# frozen_string_literal: true
require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'csv'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Reckoning
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Berlin'

    # The default locale is :de and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.default_locale = :de
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]

    config.i18n.fallbacks = [:de]

    config.action_view.field_error_proc = proc { |html_tag, _instance|
      safe_join(html_tag.to_s)
    }

    config.exceptions_app = routes

    config.middleware.use I18n::JS::Middleware
    config.middleware.insert_before 0, Rack::Cors, debug: true, logger: -> { Rails.logger } do
      allow do
        origins '*'
        resource '*', headers: :any,
                      methods: [:get, :post, :delete, :put, :options, :head],
                      max_age: 0
      end
    end

    if ENV['HTTP_USER'].present? && ENV['HTTP_PASSWORD'].present?
      # Basic authentication for Heroku Stage
      config.middleware.use '::Rack::Auth::Basic' do |user, password|
        [user, password] == [ENV['HTTP_USER'], ENV['HTTP_PASSWORD']]
      end
    end
  end
end

I18n.config.enforce_available_locales = true

require_relative 'version'
