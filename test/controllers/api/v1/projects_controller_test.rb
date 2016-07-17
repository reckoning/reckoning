# encoding: utf-8
# frozen_string_literal: true
require 'test_helper'

module Api
  module V1
    class ProjectsControllerTest < ActionController::TestCase
      setup do
        @request.headers['Accept'] = Mime[:json]
        @request.headers['Content-Type'] = Mime[:json].to_s
      end

      tests ::Api::V1::ProjectsController

      fixtures :all

      let(:project) { projects :narendra3 }

      describe "unauthorized" do
        it "Unauthrized user cant view projects index" do
          get :index

          assert_response :forbidden
          json = JSON.parse response.body
          assert_equal "authentication.missing", json["code"]
        end

        it "Unauthrized user cant destroy project" do
          delete :destroy, params: { id: project.id }

          assert_response :forbidden

          assert_equal project, Project.where(id: project.id).first
        end
      end

      describe "happy path" do
        let(:will) { users :will }
        let(:outpost6) { projects :outpost6 }

        before do
          add_authorization will
        end

        it "renders a projects list" do
          get :index

          assert_response :ok
        end

        it "destroys a project" do
          delete :destroy, params: { id: outpost6.id }

          assert_response :ok

          assert_not_equal outpost6, Project.find_by(id: outpost6.id)
        end
      end
    end
  end
end
