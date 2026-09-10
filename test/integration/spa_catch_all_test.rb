# frozen_string_literal: true

require "test_helper"

# The SPA owns every path nothing else claims. What "nothing else" means is
# the point of this test: the API, the docs, the healthcheck, the admin, the
# exports and the PDFs are not screens, and a request for one of them must
# not come back as a shell.
class SpaCatchAllTest < ActionDispatch::IntegrationTest
  let(:admin) { users :jeanluc }

  def shell?
    response.body.include?('id="spa"')
  end

  it "answers a path nothing names with the shell" do
    get "/expenses/import"

    assert_response :success
    assert shell?
  end

  it "leaves the api to the api" do
    get "/api/v1/me", headers: {"Accept" => "application/json"}

    assert_response :unauthorized
    refute shell?
  end

  it "leaves the healthcheck and the docs alone" do
    get "/up"

    assert_response :success
    refute shell?
  end

  it "leaves the admin to the admin" do
    sign_in admin

    get "/backend/users"

    assert_response :success
    refute shell?
  end

  # Same path as the SPA's expenses list, in another format.
  it "leaves an export in its own format" do
    sign_in admin
    admin.account.update_columns(feature_expenses: true)

    get "/expenses.csv"

    assert_response :success
    assert_equal "text/csv", response.media_type
  end

  # A missing asset is a missing asset, not a screen — whatever it asks for.
  it "does not answer a request for something that is not a page" do
    get "/nope.json", headers: {"Accept" => "application/json"}
    assert_response :not_found

    get "/vite/gone-abc123.js", headers: {"Accept" => "*/*"}
    assert_response :not_found
  end

  # `*/*` is what a plain `curl` and a `fetch` without an Accept header send.
  # A screen that only answers a browser is a screen that is hard to debug.
  it "answers a client that asks for nothing in particular" do
    get "/login", headers: {"Accept" => "*/*"}

    assert_response :success
    assert shell?
  end

  # The paths above are the server's whether or not it has a route for the
  # one being asked for: a typo under them is a 404, not a screen.
  it "leaves a typo under a server-owned path a typo" do
    ["/api", "/api/v1/nope", "/api-docs/nope", "/backend/nope", "/cable/nope", "/rails/nope"].each do |path|
      get path

      assert_response :not_found, "#{path} came back as #{response.status}"
      refute shell?, "#{path} came back as the shell"
    end
  end

  # Segment by segment, or a screen whose name merely starts like one of them
  # would be unreachable.
  it "keeps a screen that only reads like a server path" do
    ["/apiary", "/cablefoo", "/upstream"].each do |path|
      get path

      assert_response :success, "#{path} came back as #{response.status}"
      assert shell?, "#{path} did not reach the shell"
    end
  end
end
