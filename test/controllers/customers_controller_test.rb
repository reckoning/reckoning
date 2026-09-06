# frozen_string_literal: true

require "test_helper"

# The customer screens are the SPA's since phase B3. What is left on the Rails
# side is the handover: the old path still resolves, so the link on the
# project list and any bookmark land on the new screen.
class CustomersControllerTest < ActionDispatch::IntegrationTest
  let(:data) { users :data }
  let(:customer) { customers :starfleet }

  it "sends the edit path to the spa" do
    sign_in data

    get "/customers/#{customer.id}/edit"

    assert_redirected_to "/app/customers/#{customer.id}/edit"
  end

  # No sign-in check of its own: the SPA route guard asks the API, and the
  # redirect target is not worth protecting — it renders the shell either way.
  it "sends a signed-out visitor there too" do
    get "/customers/#{customer.id}/edit"

    assert_redirected_to "/app/customers/#{customer.id}/edit"
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
