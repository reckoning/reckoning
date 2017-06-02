# encoding: utf-8
# frozen_string_literal: true

if ENV['HTTP_USER'].present? && ENV['HTTP_PASSWORD'].present?
  # Basic authentication for Heroku Stage
  Rails.application.config.middleware.use '::Rack::Auth::Basic' do |user, password|
    user == ENV['HTTP_USER'] && password == ENV['HTTP_PASSWORD']
  end
end
