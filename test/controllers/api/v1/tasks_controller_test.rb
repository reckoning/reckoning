# encoding: utf-8
# frozen_string_literal: true
require 'test_helper'

module Api
  module V1
    class TasksControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests ::Api::V1::TasksController

      fixtures :all

      let(:task) { tasks :away_mission }

      describe "unauthorized" do
        it "Unauthrized user cant view tasks index" do
          get :index

          assert_response :forbidden
          json = JSON.parse response.body
          assert_equal "authentication.missing", json["code"]
        end

        it "Unauthrized user cant create new task" do
          post :create, params: { task: { name: "foo" } }

          assert_response :forbidden
        end
      end

      describe "happy path" do
        let(:will) { users :will }

        before do
          add_authorization will
        end

        it "renders a tasks list" do
          get :index

          assert_response :ok
        end

        it "creates a new task" do
          post :create, params: { name: "foo", projectUuid: task.project_id }

          assert_response :created

          json = JSON.parse response.body
          assert json["uuid"]
          assert_equal "foo", json["name"]
        end
      end
    end
  end
end
