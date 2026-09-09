# frozen_string_literal: true

require "test_helper"

# The login moved into the SPA. What the server still owns is the handover:
# sending a visitor there, and telling it where they were going so they end up
# back on the server-rendered screen rather than on the SPA dashboard.
#
# The screen used to show it is the backend's user list: any server-rendered
# one that asks for a session will do, and the backend is what is left. It
# used to be the CSV import, which is the SPA's now.
class LoginTest < ActionDispatch::IntegrationTest
  let(:user) { users(:will) }

  it "sends /signin to the spa login" do
    get "/signin"

    assert_redirected_to "/app/login"
  end

  it "hands over the screen a signed-out visitor asked for" do
    get "/backend/users"

    assert_redirected_to "/app/login?return=%2Fbackend%2Fusers"
  end

  it "keeps the query of the screen it hands over" do
    get "/backend/users?page=2"

    assert_redirected_to "/app/login?return=%2Fbackend%2Fusers%3Fpage%3D2"
  end

  # The login ends in a page load, so a carried path is fetched with a GET
  # whatever the request that failed was. A PATCH replayed as a GET is a route
  # that does not exist.
  it "does not carry a path that cannot be replayed" do
    post "/backend/users", params: {user: {email: "q@continuum"}}

    assert_redirected_to "/signin"
    follow_redirect!
    assert_redirected_to "/app/login"
  end

  # An xhr request never reaches the handover at all: Devise answers it with
  # 401 before `redirect_url` is consulted (`http_authenticatable_on_xhr`).
  it "answers an xhr request instead of handing it over" do
    get "/backend/users", xhr: true

    assert_response :unauthorized
  end

  it "leaves no alert behind for the next server-rendered page" do
    get "/backend/users"
    follow_redirect!

    # Devise flashes "you need to sign in" for a login screen that no longer
    # renders it. Left in the session it would surface on the page the visitor
    # reaches after signing in.
    assert_nil flash[:alert]
  end

  it "still answers json with a 401 rather than a redirect" do
    get "/backend/users", headers: {"Accept" => "application/json"}

    assert_response :unauthorized
    assert_equal "unauthorized", JSON.parse(response.body)["code"]
  end

  it "lets a signed-in user through untouched" do
    sign_in users(:jeanluc)

    get "/backend/users"

    assert_response :success
  end
end
