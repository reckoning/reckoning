# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class PlansTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/plans" do
        get("The plans the welcome page prices") do
          operationId "plans"
          tags "Plans"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Plans
          end
        end
      end

      # The page that reads this is the one a visitor sees before they have an
      # account, so it answers without a session.
      it "answers a visitor" do
        assert_api_response :get, 200 do
          codes = parsed_body.map { |plan| plan["code"] }

          assert_includes codes, "basic"
        end
      end

      it "prices them in cents, cheapest first" do
        assert_api_response :get, 200 do
          prices = parsed_body.map { |plan| plan["price"] }

          assert_equal prices.sort, prices
          assert_equal 900, parsed_body.find { |plan| plan["code"] == "basic" }["price"]
        end
      end

      # `plans.desc.<code>` is what the pricing table lists under the price.
      it "carries what each plan includes" do
        assert_api_response :get, 200 do
          basic = parsed_body.find { |plan| plan["code"] == "basic" }

          assert_equal I18n.t("plans.desc.basic").values.map(&:to_s), basic["descriptions"]
          refute_empty basic["descriptions"]
        end
      end

      it "marks the one the page highlights" do
        assert_api_response :get, 200 do
          assert parsed_body.find { |plan| plan["code"] == "plus" }["featured"]
        end
      end
    end
  end
end
