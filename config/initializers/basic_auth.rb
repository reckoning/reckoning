# frozen_string_literal: true

if ENV["HTTP_USER"].present? && ENV["HTTP_PASSWORD"].present?
  Rails.application.config.middleware.use "::Rack::Auth::Basic" do |user, password|
    [user, password] == [ENV.fetch("HTTP_USER", nil), ENV.fetch("HTTP_PASSWORD", nil)]
  end
end
