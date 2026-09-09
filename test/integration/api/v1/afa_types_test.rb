# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class AfaTypesTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/afa_types" do
        get("Depreciation classes") do
          operationId "afaTypes"
          tags "Expenses"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::AfaTypes
          end

          response(403, "expenses not enabled for this account") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:account) { accounts :enterprise }

      before { account.update!(feature_expenses: true) }

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      describe "when the account has expenses switched off" do
        before do
          account.update!(feature_expenses: false)
          sign_in data
        end

        it "is forbidden" do
          assert_api_response :get, 403 do
            assert_equal "feature.disabled", parsed_body["code"]
          end
        end
      end

      describe "signed in" do
        before { sign_in data }

        # The form offers these once an expense's type is AfA, so it needs
        # the years to write off over along with the name to show.
        it "lists the classes with their names and years" do
          assert_api_response :get, 200 do
            entry = parsed_body.find { |item| item["id"] == afa_types(:three_years).id }

            assert entry, "expected the fixture class in the list"
            assert_equal 3, entry["value"]
          end
        end

        # A reference table, the same for everyone: the account has none of
        # its own, so nothing to scope.
        it "lists every class the table has" do
          assert_api_response :get, 200 do
            assert_equal ::AfaType.count, parsed_body.size
          end
        end
      end
    end
  end
end
