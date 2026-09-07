# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    # Its own class because the DSL matches requests on verb and path params,
    # which cannot tell `GET /offers` and `GET /offers/summary` apart.
    class OfferSummaryTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/offers/summary" do
        get("What the filtered offers add up to") do
          operationId "offerSummary"
          tags "Offers"
          produces "application/json"

          parameter name: "state", in: :query, required: false,
            schema: {type: :string, enum: %w[created bided accepted declined canceled]}
          parameter name: "year", in: :query, required: false, schema: {type: :integer}

          response(200, "successful") do
            schema ::V1::Schemas::OfferSummary
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:account) { accounts :enterprise }

      # `before_save :set_value` recomputes the column from the offer's
      # positions, so a value assigned on create is thrown away. These tests
      # are about the summing, not about where a single offer's value comes
      # from, so they write it past the callback.
      def offer_worth(value, date: Date.new(2026, 3, 1))
        offer = account.offers.create!(
          project: projects(:narendra3), date: date
        )
        offer.update_columns(value: value)
        offer
      end

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      describe "signed in" do
        before do
          sign_in data
          account.offers.destroy_all
        end

        it "adds up the account's offers" do
          offer_worth(100)
          offer_worth(250)

          assert_api_response :get, 200 do
            assert_equal 2, parsed_body["count"]
            assert_equal "350.0", parsed_body["value"]
          end
        end

        # The numbers have to belong to the set the list is showing, not to
        # everything — otherwise the total under a filtered table is a lie.
        it "counts only what the filter leaves" do
          offer_worth(100, date: Date.new(2026, 3, 1))
          offer_worth(900, date: Date.new(2025, 3, 1))

          assert_api_response :get, 200, params: {year: 2026} do
            assert_equal 1, parsed_body["count"]
            assert_equal "100.0", parsed_body["value"]
          end
        end

        # The year dropdown needs the years you could switch to, so this one
        # ignores the filters on purpose.
        it "offers every year the account has offers in" do
          offer_worth(100, date: Date.new(2026, 3, 1))
          offer_worth(900, date: Date.new(2024, 7, 1))

          assert_api_response :get, 200, params: {year: 2026} do
            assert_equal 1, parsed_body["count"]
            assert_equal [2026, 2024], parsed_body["years"]
          end
        end

        # The `two` fixture belongs to the defiant account.
        it "leaves another account's offers out" do
          offer_worth(100)

          assert_api_response :get, 200 do
            assert_equal 1, parsed_body["count"]
            assert_equal "100.0", parsed_body["value"]
          end
        end
      end
    end
  end
end
