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

  # A missing asset is a missing asset, not a screen.
  it "does not answer a request for something that is not a page" do
    get "/nope.json", headers: {"Accept" => "application/json"}

    assert_response :not_found
  end
end
