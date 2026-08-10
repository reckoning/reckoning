# frozen_string_literal: true

require "openapi_helper"

# Own class: /timers and /timers/uninvoiced are both parameterless GETs.
module Api
  module V1
    class UninvoicedTimersTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/timers/uninvoiced" do
        get("Timers eligible for an invoice position") do
          operationId "uninvoicedTimers"
          tags "Timers"
          produces "application/json"

          parameter name: "projectId", in: :query, required: false,
            schema: {type: :string, format: :uuid}
          parameter name: "withoutIds", in: :query, required: false,
            description: "Timer ids to exclude — typically those already staged in the editor.",
            schema: {type: :array, items: {type: :string, format: :uuid}}

          response(200, "successful") do
            schema ::V1::Schemas::Timers
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:task) { tasks :away_mission }
      let(:timer) { timers :twohours }

      it "is unauthorized when signed out" do
        assert_api_response :get, 401
      end

      describe "signed in" do
        before { sign_in data }

        it "lists billable, uninvoiced, non-empty timers" do
          assert_api_response :get, 200 do
            assert_includes parsed_body.map { |item| item["id"] }, timer.id
            assert(parsed_body.none? { |item| item["invoiced"] })
          end
        end

        it "excludes timers already on an invoice position" do
          position = InvoicePosition.create!(
            invoicable: invoices(:january),
            description: "Away missions",
            hours: 2
          )
          timer.update!(position: position)

          assert_api_response :get, 200 do
            refute_includes parsed_body.map { |item| item["id"] }, timer.id
          end
        end

        it "excludes ids passed in withoutIds" do
          assert_api_response :get, 200, params: {withoutIds: [timer.id]} do
            refute_includes parsed_body.map { |item| item["id"] }, timer.id
          end
        end

        it "excludes non-billable work" do
          task.update!(billable: false)

          assert_api_response :get, 200 do
            refute_includes parsed_body.map { |item| item["id"] }, timer.id
          end
        end

        it "filters by project" do
          other = projects :outpost6

          assert_api_response :get, 200, params: {projectId: other.id} do
            refute_includes parsed_body.map { |item| item["id"] }, timer.id
          end
        end
      end
    end
  end
end
