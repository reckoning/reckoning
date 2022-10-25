# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class ProjectsControllerTest < ActionDispatch::IntegrationTest
      let(:project) { projects :narendra3 }

      describe 'unauthorized' do
        it 'Unauthrized user cant view projects index' do
          get '/api/v1/projects'

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'Unauthrized user cant destroy project' do
          delete "/api/v1/projects/#{project.id}"

          assert_response :unauthorized

          assert_equal project, Project.where(id: project.id).first
        end
      end

      describe 'happy path' do
        let(:will) { users :will }
        let(:outpost6) { projects :outpost6 }

        before do
          sign_in will
        end

        it 'renders a projects list' do
          get '/api/v1/projects'

          assert_response :ok
        end

        it 'destroys a project' do
          delete "/api/v1/projects/#{outpost6.id}"

          assert_response :ok

          assert_not_equal outpost6, Project.find_by(id: outpost6.id)
        end
      end
    end
  end
end
