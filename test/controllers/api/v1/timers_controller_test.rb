# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class TimersControllerTest < ActionDispatch::IntegrationTest
      let(:timer) { timers :threehours }

      describe 'unauthorized' do
        it 'Unauthrized user cant view timers index' do
          get '/api/v1/timers'

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'Unauthrized user cant create new timer' do
          post '/api/v1/timers', params: { timer: { date: Time.current, value: 1.0, taskUuid: timer.task_id } }

          assert_response :unauthorized
        end

        it 'Unauthrized user cant update a timer' do
          put "/api/v1/timers/#{timer.id}"

          assert_response :unauthorized
        end

        it 'Unauthrized user cant start a timer' do
          put "/api/v1/timers/#{timer.id}/start"

          assert_response :unauthorized
        end

        it 'Unauthrized user cant stop a timer' do
          put "/api/v1/timers/#{timer.id}/stop"

          assert_response :unauthorized
        end

        it 'Unauthrized user cant destroy timer' do
          delete "/api/v1/timers/#{timer.id}"

          assert_response :unauthorized

          assert_equal timer, Timer.find_by(id: timer.id)
        end
      end

      describe 'happy path' do
        let(:will) { users :will }
        let(:outpost6) { projects :outpost6 }

        before do
          sign_in will
        end

        it 'renders a timers list' do
          get '/api/v1/timers'

          assert_response :ok
        end

        it 'creates a new timer' do
          date = Time.current.to_date
          post '/api/v1/timers', params: { date: date, value: 1.0, task_id: timer.task_id }

          assert_response :created

          json = JSON.parse response.body
          assert json['id']
          assert_equal '1.0', json['value']
          assert_equal I18n.l(date, format: :db), json['date']
        end

        it 'updates a timer' do
          patch "/api/v1/timers/#{timer.id}", params: { value: 2.0, task_id: timer.task_id }

          assert_response :ok

          json = JSON.parse response.body
          assert json['id']
          assert_equal '2.0', json['value']
        end

        it 'starts a timer' do
          put "/api/v1/timers/#{timer.id}/start"

          assert_response :ok

          json = JSON.parse response.body
          assert json['started']
          assert json['startedAt']
        end

        it 'stops a timer' do
          timer.update(started_at: Time.current.to_date)
          put "/api/v1/timers/#{timer.id}/stop"

          assert_response :ok

          json = JSON.parse response.body
          assert_not json['started']
        end

        it 'destroys a timer' do
          delete "/api/v1/timers/#{timer.id}"

          assert_response :ok

          assert_not_equal timer, Timer.find_by(id: timer.id)
        end
      end
    end
  end
end
