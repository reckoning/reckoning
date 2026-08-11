# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class OfferTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/offers/{id}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true

        get("Get Offer") do
          operationId "offer"
          tags "Offers"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Offer
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        patch("Update Offer") do
          operationId "updateOffer"
          tags "Offers"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::OfferInput}
          }

          response(200, "successful") do
            schema ::V1::Schemas::Offer
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(403, "not editable in this state") do
            schema ::V1::Schemas::Message
          end

          response(404, "not found") do
            schema ::V1::Schemas::StandardError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        delete("Destroy Offer") do
          operationId "destroyOffer"
          tags "Offers"
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

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:offer) { offers :one }

      before { sign_in data }

      it "shows an offer" do
        assert_api_response :get, 200, path_params: {id: offer.id} do
          assert_equal offer.id, parsed_body["id"]
        end
      end

      it "updates an offer while it is still editable" do
        assert_api_response :patch, 200, path_params: {id: offer.id}, body: {description: "Revised scope"} do
          assert_equal "Revised scope", parsed_body["description"]
        end
      end

      # `can :update` only holds while created or bided.
      it "refuses to update an accepted offer" do
        offer.bid!
        offer.accept!

        assert_api_response :patch, 403, path_params: {id: offer.id}, body: {description: "Too late"}
      end

      it "destroys an offer" do
        assert_api_response :delete, 200, path_params: {id: offer.id}

        assert_nil Offer.find_by(id: offer.id)
      end
    end
  end
end
