# frozen_string_literal: true

require "test_helper"

# The customer screens are the SPA's since phase B3, and the SPA is mounted at
# the root — so the path the project list links is served by the shell rather
# than handed anywhere.
class CustomersControllerTest < ActionDispatch::IntegrationTest
  let(:data) { users :data }
  let(:customer) { customers :starfleet }

  it "serves the edit path from the shell" do
    sign_in data

    get "/customers/#{customer.id}/edit"

    assert_response :success
    assert_select "div#spa"
  end

  # No sign-in check of its own: the SPA route guard asks the API, and the
  # shell is not worth protecting — it renders either way.
  it "serves a signed-out visitor too" do
    get "/customers/#{customer.id}/edit"

    assert_response :success
    assert_select "div#spa"
  end

  # The SPA writes through the API, so the route the ERB form posted to is
  # gone rather than left dangling.
  it "no longer answers the update it used to serve" do
    sign_in data

    put "/customers/#{customer.id}", params: {customer: {name: "bar"}}

    assert_response :not_found
    assert_equal "Starfleet", customer.reload.name
  end
end
