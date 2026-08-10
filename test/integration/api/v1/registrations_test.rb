# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class RegistrationsTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/registrations" do
        post("Sign up: create an account and its first user") do
          operationId "createRegistration"
          tags "Registrations"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::RegistrationInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Registration
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(403, "registration disabled") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:valid_body) do
        {
          name: "Vulcan Science Academy",
          plan: "free",
          users_attributes: [
            {email: "t.pol@vulcan.gov", password: "logic-is-the-beginning", password_confirmation: "logic-is-the-beginning"}
          ]
        }
      end

      before do
        @registration = Rails.configuration.app.registration
        Rails.configuration.app.registration = true
      end

      after { Rails.configuration.app.registration = @registration }

      it "creates an account with its first user" do
        assert_difference ["Account.count", "User.count"], 1 do
          assert_api_response :post, 201, body: valid_body do
            assert_equal "Vulcan Science Academy", parsed_body["name"]
          end
        end

        assert User.find_by(email: "t.pol@vulcan.gov")
      end

      it "rejects a signup without a user" do
        assert_api_response :post, 400, body: valid_body.merge(users_attributes: []) do
          assert_equal "validation_error.account.create", parsed_body["code"]
        end
      end

      it "rejects a duplicate email" do
        body = valid_body.deep_dup
        body[:users_attributes][0][:email] = users(:data).email

        assert_no_difference "Account.count" do
          assert_api_response :post, 400, body: body
        end
      end

      it "is forbidden when registration is switched off" do
        Rails.configuration.app.registration = false

        assert_no_difference "Account.count" do
          assert_api_response :post, 403, body: valid_body do
            assert_equal "registration.disabled", parsed_body["code"]
          end
        end
      end
    end
  end
end
