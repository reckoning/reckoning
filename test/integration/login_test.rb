# frozen_string_literal: true

require "test_helper"

# The login moved into the SPA. What the server still owns is the handover:
# sending a visitor there, and telling it where they were going so they end up
# back on the server-rendered screen rather than on the SPA dashboard.
#
# The screen used to show it is the CSV import: any server-rendered one that
# asks for a session will do, and that is the one still left. It used to be
# the profile, which is the SPA's now.
class LoginTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }

  it "sends /signin to the spa login" do
    get "/signin"

    assert_redirected_to "/app/login"
  end

  it "hands over the screen a signed-out visitor asked for" do
    get "/expense_imports/new"

    assert_redirected_to "/app/login?return=%2Fexpense_imports%2Fnew"
  end

  it "keeps the query of the screen it hands over" do
    get "/expense_imports/new?year=2026"

    assert_redirected_to "/app/login?return=%2Fexpense_imports%2Fnew%3Fyear%3D2026"
  end

  # The login ends in a page load, so a carried path is fetched with a GET
  # whatever the request that failed was. A PATCH replayed as a GET is a route
  # that does not exist.
  it "does not carry a path that cannot be replayed" do
    post "/expense_imports", params: {expense_import: {rows: {}}}

    assert_redirected_to "/signin"
    follow_redirect!
    assert_redirected_to "/app/login"
  end

  # An xhr request never reaches the handover at all: Devise answers it with
  # 401 before `redirect_url` is consulted (`http_authenticatable_on_xhr`).
  it "answers an xhr request instead of handing it over" do
    get "/expense_imports/new", xhr: true

    assert_response :unauthorized
  end

  it "leaves no alert behind for the next server-rendered page" do
    get "/expense_imports/new"
    follow_redirect!

    # Devise flashes "you need to sign in" for a login screen that no longer
    # renders it. Left in the session it would surface on the page the visitor
    # reaches after signing in.
    assert_nil flash[:alert]
  end

  it "still answers json with a 401 rather than a redirect" do
    get "/expense_imports/new", headers: {"Accept" => "application/json"}

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["code"]
  end

  it "lets a signed-in user through untouched" do
    user.account.update_columns(feature_expenses: true)
    sign_in user

    get "/expense_imports/new"

    assert_response :success
  end
end
