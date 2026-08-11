# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class OfferTransitionTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/offers/{id}/transition/{event}" do
        parameter name: "id", in: :path, schema: {type: :string, format: :uuid}, required: true
        parameter name: "event", in: :path, required: true,
          description: "State machine event to apply.",
          schema: {type: :string, enum: %w[bid accept decline cancel]}

        put("Move an offer through its state machine") do
          operationId "transitionOffer"
          tags "Offers"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::Offer
          end

          response(400, "event does not apply in this state") do
            schema ::V1::Schemas::ValidationError
          end

          response(403, "forbidden") do
            schema ::V1::Schemas::Message
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

      it "bids a created offer" do
        assert_api_response :put, 200, path_params: {id: offer.id, event: "bid"} do
          assert_equal "bided", parsed_body["state"]
          refute parsed_body["editable"]
        end
      end

      it "accepts a bided offer" do
        offer.bid!

        assert_api_response :put, 200, path_params: {id: offer.id, event: "accept"} do
          assert_equal "accepted", parsed_body["state"]
        end
      end

      # created -> accepted is not a transition AASM allows.
      it "refuses an event that does not apply in the current state" do
        assert_api_response :put, 400, path_params: {id: offer.id, event: "accept"} do
          assert_equal "validation_error.offer.transition", parsed_body["code"]
        end

        assert_equal "created", offer.reload.aasm_state
      end

      it "rejects an unknown event" do
        assert_api_response :put, 400, path_params: {id: offer.id, event: "explode"}
      end
    end
  end
end
