# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class TasksControllerTest < ActionDispatch::IntegrationTest
      let(:project) { projects :narendra3 }
      let(:task) { tasks :away_mission }

      describe "unauthorized" do
        it "Unauthrized user cant view tasks index" do
          get "/api/v1/tasks"

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal "unauthorized", json["code"]
        end

        it "Unauthrized user cant create new task" do
          post "/api/v1/tasks", params: {task: {name: "foo"}}

          assert_response :unauthorized
        end
      end

      describe "happy path" do
        let(:will) { users :will }

        before do
          sign_in will
        end

        it "renders a tasks list" do
          get "/api/v1/tasks"

          assert_response :ok
        end

        it "scopes a task's timers to the requested week" do
          in_week = will.timers.create!(task: task, date: Date.new(2026, 6, 11), value: 4)
          will.timers.create!(task: task, date: Date.new(2026, 6, 3), value: 5)

          get "/api/v1/tasks", params: {weekDate: "2026-06-10"}

          assert_response :ok
          json = JSON.parse response.body
          entry = json.find { |t| t["id"] == task.id }
          assert_equal [in_week.id], entry["timers"].map { |t| t["id"] }
          assert_equal task.id, entry["timers"].first["taskId"]
        end

        it "creates a new task" do
          post "/api/v1/tasks", params: {name: "foo", project_id: project.id}

          assert_response :created

          json = JSON.parse response.body
          assert json["id"]
          assert_equal "foo", json["name"]
        end
      end
    end
  end
end
