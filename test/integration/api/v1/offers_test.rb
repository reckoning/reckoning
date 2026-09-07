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
          parameter name: "sort", in: :query, required: false,
            description: "Column to order by. Anything else falls back to the newest first.",
            schema: {type: :string, enum: %w[ref date value state customer]}
          parameter name: "direction", in: :query, required: false,
            schema: {type: :string, enum: %w[asc desc]}

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
      let(:account) { accounts :enterprise }

      # `before_create :set_ref` numbers the offer, so the order the sorting
      # tests check is the one the account would really produce.
      def offer_dated(date)
        account.offers.create!(project: project, date: date)
      end

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

        # The server-rendered list sorted by five columns; the endpoint only
        # ever answered newest-first.
        it "sorts by the columns the list offers" do
          low = offer_dated(Date.new(2026, 1, 5))
          high = offer_dated(Date.new(2026, 6, 5))

          assert_api_response :get, 200, params: {sort: "date", direction: "asc"} do
            ids = parsed_body.map { |item| item["id"] }

            assert_operator ids.index(low.id), :<, ids.index(high.id)
          end

          assert_api_response :get, 200, params: {sort: "date", direction: "desc"} do
            ids = parsed_body.map { |item| item["id"] }

            assert_operator ids.index(high.id), :<, ids.index(low.id)
          end
        end

        # Dates, values, states and customer names all repeat, and offset
        # paging over a tie can show a row twice or skip it. `ref` closes the
        # order so nothing is left undecided.
        it "breaks ties by ref so paging cannot repeat a row" do
          first = offer_dated(Date.new(2026, 3, 1))
          second = offer_dated(Date.new(2026, 3, 1))

          assert_api_response :get, 200, params: {sort: "date", direction: "asc"} do
            tied = parsed_body
              .select { |item| item["date"] == "2026-03-01" }
              .map { |item| item["id"] }

            assert_equal [second.id, first.id], tied & [second.id, first.id]
          end
        end

        # Without a sort it stays what it always was: newest ref first.
        it "falls back to the newest first" do
          low = offer_dated(Date.new(2026, 1, 5))
          high = offer_dated(Date.new(2026, 6, 5))

          assert_api_response :get, 200 do
            ids = parsed_body.map { |item| item["id"] }

            assert_operator ids.index(high.id), :<, ids.index(low.id)
          end
        end

        # `filter_state` used to check the *invoice* workflow's state names,
        # which share only `created` with the offer's — every other filter
        # quietly returned the whole list.
        it "filters by state" do
          bided = offer_dated(Date.new(2026, 1, 5))
          bided.bid!

          assert_api_response :get, 200, params: {state: "bided"} do
            ids = parsed_body.map { |item| item["id"] }

            assert_equal [bided.id], ids
          end

          assert_api_response :get, 200, params: {state: "created"} do
            ids = parsed_body.map { |item| item["id"] }

            refute_includes ids, bided.id
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
