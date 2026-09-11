# frozen_string_literal: true

require "test_helper"

# The login moved into the SPA. What the server still owns is the handover:
# sending a visitor there, and telling it where they were going so they end up
# back on the server-rendered screen rather than on the SPA dashboard.
#
# The screen used to show it is Sidekiq's dashboard: any server-rendered one
# that asks for a session will do, and the two engines mounted under
# `/backend` are what is left — the admin screens themselves are the SPA's
# now.
class LoginTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }

  it "sends /signin to the spa login" do
    get "/signin"

    assert_redirected_to "/login"
  end

  it "hands over the screen a signed-out visitor asked for" do
    get "/backend/workers"

    assert_redirected_to "/login?return=%2Fbackend%2Fworkers%2F"
  end

  it "keeps the query of the screen it hands over" do
    get "/backend/workers?page=2"

    assert_redirected_to "/login?return=%2Fbackend%2Fworkers%2F%3Fpage%3D2"
  end

  # The login ends in a page load, so a carried path is fetched with a GET
  # whatever the request that failed was. Anything else replayed as a GET is
  # a route that does not exist, so it travels with nothing.
  it "does not carry a path that cannot be replayed" do
    post "/backend/workers"

    assert_redirected_to "/signin"
    follow_redirect!
    assert_redirected_to "/login"
  end

  # An xhr request never reaches the handover at all: Devise answers it with
  # 401 before `redirect_url` is consulted (`http_authenticatable_on_xhr`).
  it "answers an xhr request instead of handing it over" do
    get "/backend/workers", xhr: true

    assert_response :unauthorized
  end

  it "leaves no alert behind for the next server-rendered page" do
    get "/backend/workers"
    follow_redirect!

    # Devise flashes "you need to sign in" for a login screen that no longer
    # renders it. Left in the session it would surface on the page the visitor
    # reaches after signing in.
    assert_nil flash[:alert]
  end

  it "still answers json with a 401 rather than a redirect" do
    get "/backend/workers", headers: {"Accept" => "application/json"}

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["code"]
  end

  it "lets a signed-in user through untouched" do
    sign_in users(:jeanluc)

    get "/backend/workers"

    assert_response :success
  end
end
