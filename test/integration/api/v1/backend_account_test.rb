# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class BackendAccountTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/backend/accounts/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        get("Get an account") do
          operationId "backendAccount"
          tags "Backend"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::BackendAccount
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(403, "not an admin") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update an account") do
          operationId "updateBackendAccount"
          tags "Backend"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::BackendAccountInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::BackendAccount
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(403, "not an admin") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        delete("Destroy an account") do
          operationId "destroyBackendAccount"
          tags "Backend"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Message
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(403, "not an admin") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:admin) { users :jeanluc }
      let(:account) { accounts :enterprise }

      describe "as an admin" do
        before { sign_in admin }

        it "shows an account" do
          assert_api_response :get, 200, path_params: {id: account.id} do
            assert_equal account.name, parsed_body["name"]
            assert_equal account.users.count, parsed_body["usersCount"]
          end
        end

        # The two features the backend form switches, and the plan.
        it "switches a feature on" do
          account.update_columns(feature_expenses: false)

          assert_api_response :patch, 200, path_params: {id: account.id},
            body: {feature_expenses: true} do
            assert parsed_body["featureExpenses"]
          end

          assert account.reload.feature_expenses
        end

        # A free plan has no trial, so the date a paid plan left behind has to
        # go with it — `trial_expired?` reads that column alone.
        it "drops the trial when an account is moved to the free plan" do
          account.update_columns(plan: "basic", trial_used: true, trial_end_at: 1.minute.ago)

          assert_api_response :patch, 200, path_params: {id: account.id}, body: {plan: "free"} do
            assert_nil parsed_body["trialEndAt"]
          end

          refute account.reload.trial_expired?
        end

        it "refuses a name that is not there" do
          assert_api_response :patch, 400, path_params: {id: account.id}, body: {name: ""} do
            assert_equal "validation_error.account.update", parsed_body["code"]
          end
        end

        # An account takes everything on it with it, which is why the backend
        # is the only place this is offered.
        it "destroys an account" do
          other = Account.create!(
            name: "Vulcan Science Academy", plan: "free",
            users: [User.new(email: "spock@vulcan.gov", password: "long-enough-password")]
          )

          assert_api_response :delete, 200, path_params: {id: other.id}

          assert_nil Account.find_by(id: other.id)
        end

        it "is not found for an unknown id" do
          assert_api_response :get, 404, path_params: {id: SecureRandom.uuid}
        end
      end

      it "is forbidden for a non-admin" do
        sign_in users(:data)

        assert_api_response :get, 403, path_params: {id: account.id}
      end

      it "is unauthorized when signed out" do
        assert_api_response :get, 401, path_params: {id: account.id}
      end
    end
  end
end
