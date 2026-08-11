# frozen_string_literal: true

require "test_helper"

class SpaControllerTest < ActionDispatch::IntegrationTest
  let(:data) { users :data }

  # The SPA renders its own login against /api/v1, so the shell has to reach an
  # anonymous visitor instead of being bounced to the ERB session screen.
  it "serves the shell to an anonymous visitor" do
    get "/app"

    assert_response :success
    assert_select "div#spa"
  end

  it "serves the shell to a signed-in user" do
    sign_in data

    get "/app"

    assert_response :success
    assert_select "div#spa"
  end

  # vue-router owns the paths beneath /app, so a reload of a client-side route
  # has to find the shell rather than a 404.
  it "serves the shell for a client-side path" do
    get "/app/customers"

    assert_response :success
    assert_select "div#spa"
  end

  # `csrf_meta_tags` is a no-op while the test environment disables forgery
  # protection, so the tag only proves anything with it switched back on.
  it "renders a csrf token for the api client" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true

    get "/app"

    assert_select "meta[name=csrf-token]"
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  # The shell must not drag in Bootstrap or the Sprockets bundle.
  it "does not load the legacy asset pipeline" do
    get "/app"

    assert_select "script[src*=?]", "application", count: 0
    assert_select "link[href*=?]", "application.css", count: 0
  end
end
