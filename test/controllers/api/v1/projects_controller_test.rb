require 'test_helper'

module Api
  module V1
    class ProjectsControllerTest < ActionController::TestCase
      tests ::Api::V1::ProjectsController

      fixtures :all

      let(:project) { projects :narendra3 }

      describe "unauthorized" do
        it "Unauthrized user cant destroy project" do
          delete :destroy, id: project.id

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

        it "User can destroy project" do
          delete :destroy, id: outpost6.id

          assert_response :ok

          assert_not_equal outpost6, Project.where(id: outpost6.id).first
        end
      end
    end
  end
end
