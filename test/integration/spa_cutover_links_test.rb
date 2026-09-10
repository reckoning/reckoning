# frozen_string_literal: true

require "test_helper"

# The SPA is mounted at the root, so most of the paths it took over are simply
# its own — the shell answers them. What still redirects is the handful the
# SPA does not name the same way it is reached by: Devise's URLs, which sit in
# mails already sent, and the two the server-rendered user menu links. Those
# have to keep what they carry — a token, a screen to return to — because
# `redirect("…")` drops the query string on the floor.
class SpaCutoverLinksTest < ActionDispatch::IntegrationTest
  let(:id) { "aaaaaaaa-0000-4000-8000-000000000001" }

  it "serves a filtered list without sending the browser anywhere" do
    get "/projects?state=archived"
    assert_response :success
    assert_select "div#spa"

    get "/invoices?year=2026&state=paid"
    assert_response :success

    get "/offers?year=2026"
    assert_response :success
  end

  it "serves a record's own screen" do
    ["/invoices/#{id}", "/invoices/#{id}/edit", "/offers/#{id}", "/offers/#{id}/edit",
      "/customers/#{id}/edit", "/projects/#{id}/edit", "/projects/new", "/timesheet"].each do |path|
      get path

      assert_response :success, "#{path} did not reach the shell"
      assert_select "div#spa"
    end
  end

  it "keeps the screen to come back to after signing in" do
    get "/signin?return=%2Fsettings"

    assert_redirected_to "/login?return=%2Fsettings"
  end

  # The paths Devise puts in its mails, and the two the legacy user menu links.
  it "leads the paths the SPA names differently to the names it knows" do
    {
      "/signin" => "/login",
      "/users/password/new" => "/password/new",
      "/users/unlock" => "/unlock",
      "/users/confirmation" => "/confirmation",
      "/me/otp" => "/settings/two-factor",
      "/account/edit" => "/account",
      "/password/edit" => "/settings/password"
    }.each do |from, to|
      get from

      assert_redirected_to to
    end
  end

  it "keeps a token on the way" do
    get "/users/password/edit?reset_password_token=a-token"

    assert_redirected_to "/password/edit?reset_password_token=a-token"
  end
end
