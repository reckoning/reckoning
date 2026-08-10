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

        it "shows an offer" do
          assert_api_response :get, 200, path_params: {id: offer.id} do
            assert_equal offer.id, parsed_body["id"]
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

    # Own class: the transition path also matches PUT with a path param.
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
