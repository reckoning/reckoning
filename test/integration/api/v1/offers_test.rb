# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class OffersTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/offers" do
        get("Offers list") do
          operationId "offers"
          tags "Offers"
          produces "application/json"

          parameter "$ref": "#/components/parameters/PageParameter"
          parameter "$ref": "#/components/parameters/PerPageParameter"
          parameter name: "state", in: :query, required: false,
            schema: {type: :string, enum: %w[created bided accepted declined canceled]}
          parameter name: "year", in: :query, required: false, schema: {type: :integer}

          response(200, "successful") do
            schema ::V1::Schemas::Offers
            header "Link", schema: {type: :string}, description: "RFC 8288 pagination links."
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create new Offer") do
          operationId "createOffer"
          tags "Offers"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::OfferInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Offer
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:offer) { offers :one }
      let(:project) { projects :narendra3 }

      describe "unauthorized" do
        it "does not list offers" do
          assert_api_response :get, 401
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "lists the account's offers with their positions" do
          assert_api_response :get, 200 do
            listed = parsed_body.find { |item| item["id"] == offer.id }

            assert listed, "expected the offer in the list"
            assert_kind_of Array, listed["positions"]
          end
        end

        it "creates an offer with positions" do
          assert_api_response :post, 201, body: {
            project_id: project.id,
            date: "2026-08-01",
            description: "Warp core overhaul",
            positions_attributes: [{description: "Design", hours: "4.0", rate: "150.0"}]
          } do
            assert_equal 1, parsed_body["positions"].size
            assert_equal "created", parsed_body["state"]
          end
        end
      end
    end
  end
end
