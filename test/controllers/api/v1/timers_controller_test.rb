# encoding: utf-8
# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class TimersControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests ::Api::V1::TimersController

      let(:timer) { timers :threehours }

      describe "unauthorized" do
        it "Unauthrized user cant view timers index" do
          get :index

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal "unauthorized", json["code"]
        end

        it "Unauthrized user cant create new timer" do
          post :create, params: { timer: { date: Time.current, value: 1.0, taskUuid: timer.task_id } }

          assert_response :unauthorized
        end

        it "Unauthrized user cant update a timer" do
          put :update, params: { id: timer.id }

          assert_response :unauthorized
        end

        it "Unauthrized user cant start a timer" do
          put :start, params: { id: timer.id }

          assert_response :unauthorized
        end

        it "Unauthrized user cant stop a timer" do
          put :stop, params: { id: timer.id }

          assert_response :unauthorized
        end

        it "Unauthrized user cant destroy timer" do
          delete :destroy, params: { id: timer.id }

          assert_response :unauthorized

          assert_equal timer, Timer.find_by(id: timer.id)
        end
      end

      describe "happy path" do
        let(:will) { users :will }
        let(:outpost6) { projects :outpost6 }

        before do
          add_authorization will
        end

        it "renders a timers list" do
          get :index

          assert_response :ok
        end

        it "creates a new timer" do
          date = Time.current.to_date
          post :create, params: { date: date, value: 1.0, taskId: timer.task_id }

          assert_response :created

          json = JSON.parse response.body
          assert json["id"]
          assert_equal "1.0", json["value"]
          assert_equal I18n.l(date, format: :db), json["date"]
        end

        it "updates a timer" do
          patch :update, params: { id: timer.id, value: 2.0, taskId: timer.task_id }

          assert_response :ok

          json = JSON.parse response.body
          assert json["id"]
          assert_equal "2.0", json["value"]
        end

        it "starts a timer" do
          put :start, params: { id: timer.id }

          assert_response :ok

          json = JSON.parse response.body
          assert_equal true, json["started"]
          assert json["startedAt"]
        end

        it "stops a timer" do
          timer.update(started_at: Time.current.to_date)
          put :stop, params: { id: timer.id }

          assert_response :ok

          json = JSON.parse response.body
          assert_equal false, json["started"]
        end

        it "destroys a timer" do
          delete :destroy, params: { id: timer.id }

          assert_response :ok

          assert_not_equal timer, Timer.find_by(id: timer.id)
        end
      end
    end
  end
end
