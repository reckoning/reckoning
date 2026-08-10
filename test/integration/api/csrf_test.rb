# frozen_string_literal: true

require "test_helper"

# The test environment disables forgery protection globally
# (config.action_controller.allow_forgery_protection = false), so it has to be
# switched on here — otherwise this passes no matter what the controller does.
module Api
  class CsrfTest < ActionDispatch::IntegrationTest
    let(:data) { users :data }

    before do
      @api_forgery_protection = Api::BaseController.allow_forgery_protection
      @html_forgery_protection = ActionController::Base.allow_forgery_protection

      Api::BaseController.allow_forgery_protection = true
      # Also on the HTML side, so `csrf_meta_tags` renders a token to read.
      ActionController::Base.allow_forgery_protection = true
    end

    after do
      Api::BaseController.allow_forgery_protection = @api_forgery_protection
      ActionController::Base.allow_forgery_protection = @html_forgery_protection
    end

    describe "cookie-authenticated requests" do
      before { sign_in data }

      it "rejects a mutation without a CSRF token" do
        post "/api/v1/customers",
          params: {name: "Vulcan High Command"}.to_json,
          headers: {"Content-Type" => "application/json", "Accept" => "application/json"}

        assert_response :unprocessable_entity
        assert_equal "invalid_authenticity_token", JSON.parse(response.body)["code"]
        assert_nil Customer.find_by(name: "Vulcan High Command")
      end

      it "accepts a mutation carrying a CSRF token" do
        post "/api/v1/customers",
          params: {name: "Vulcan High Command"}.to_json,
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json",
            "X-CSRF-Token" => csrf_token_from_page
          }

        assert_response :created
        assert Customer.find_by(name: "Vulcan High Command")
      end

      it "still allows reads without a token" do
        get "/api/v1/customers"

        assert_response :ok
      end
    end

    describe "token-authenticated requests" do
      it "does not require a CSRF token" do
        auth_token = AuthToken.create!(user_id: data.id)

        post "/api/v1/customers",
          params: {name: "Andorian Guard"}.to_json,
          headers: {
            "Content-Type" => "application/json",
            "Accept" => "application/json",
            "Authorization" => "Bearer #{JsonWebToken.encode(auth_token.to_jwt_payload)}"
          }

        assert_response :created
        assert Customer.find_by(name: "Andorian Guard")
      end
    end

    # The SPA shell will read the token the same way the current app does —
    # from the `csrf-token` meta tag Rails renders into the layout.
    private def csrf_token_from_page
      get "/"

      css_select("meta[name=csrf-token]").first["content"]
    end
  end
end
