# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    # Its own class because the DSL matches on verb and path params, which
    # cannot tell `GET /projects/{id}` and `GET /projects/{id}/chart` apart.
    class ProjectChartTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/projects/{id}/chart" do
        parameter name: "id", in: :path, required: true, schema: {type: :string, format: :uuid}

        get("What a project's budget chart is drawn from") do
          operationId "projectChart"
          tags "Projects"
          produces "application/json"

          response(200, "successful") do
            schema ::V1::Schemas::ProjectChart
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
      let(:account) { accounts :enterprise }
      let(:project) { projects :narendra3 }

      it "is unauthorized when signed out" do
        assert_api_response :get, 401, path_params: {id: project.id}
      end

      describe "signed in" do
        before { sign_in data }

        # A week per label, from the project's start to its end, and the
        # months are where the axis is labelled.
        it "reports a week per label and the months among them" do
          project.update!(start_date: 8.weeks.ago, end_date: 1.week.from_now, budget: 10_000, rate: 100)

          assert_api_response :get, 200, path_params: {id: project.id} do
            assert_operator parsed_body["labels"].size, :>=, 8
            assert_kind_of Array, parsed_body["ticks"]
            assert_equal 10_000.0, parsed_body["budget"].to_f
          end
        end

        # The line the work is measured against, and the work itself as a
        # running total of what has been booked and is billable.
        # `outpost6` rather than the project the timer fixtures hang off, so
        # the sum is only what this test booked.
        it "adds the billable work up week by week" do
          quiet = projects(:outpost6)
          quiet.update!(start_date: 3.weeks.ago, end_date: 1.week.from_now, budget: 10_000, rate: 100)
          task = quiet.tasks.create!(name: "Away mission", billable: true)
          # A timer belongs to a task, which is what ties it to the project.
          task.timers.create!(user: data, date: 2.weeks.ago.to_date, value: 5)

          assert_api_response :get, 200, path_params: {id: quiet.id} do
            series = parsed_body["datasets"].first

            assert series, "expected a series for a project with a budget"
            # 5 hours at 100 an hour, carried forward from the week it was
            # booked in.
            assert_equal 500.0, series["data"].last.to_f
            assert_kind_of Integer, series["zone"]
          end
        end

        # Without a budget there is nothing to measure against, so the chart
        # has labels and no series rather than a line at zero.
        it "draws no series for a project without a budget" do
          project.update!(budget: 0)

          assert_api_response :get, 200, path_params: {id: project.id} do
            assert_empty parsed_body["datasets"]
          end
        end

        it "is not found for another account's project" do
          other = accounts(:defiant).customers.create!(name: "Tal Shiar")
            .projects.create!(name: "Cloaking device")

          assert_api_response :get, 404, path_params: {id: other.id}
        end
      end
    end
  end
end
