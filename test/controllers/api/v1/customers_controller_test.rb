# frozen_string_literal: true

require 'test_helper'

module Api
  module V1
    class CustomersControllerTest < ActionDispatch::IntegrationTest
      let(:data) { users :data }
      let(:customer) { customers :starfleet }

      describe 'unauthorized' do
        it 'Unauthrized user cant view customers index' do
          get '/api/v1/customers'

          assert_response :unauthorized
          json = JSON.parse response.body
          assert_equal 'unauthorized', json['code']
        end

        it 'Unauthrized user cant view customer' do
          get "/api/v1/customers/#{customer.id}"

          assert_response :unauthorized
        end

        it 'Unauthrized user cant create new customer' do
          post '/api/v1/customers', params: { customer: { name: 'foo' } }

          assert_response :unauthorized
        end

        it 'Unauthrized user cant destroy customer' do
          delete "/api/v1/customers/#{customer.id}"

          assert_response :unauthorized

          assert_equal customer, Customer.find_by(id: customer.id)
        end
      end

      describe 'happy path' do
        before do
          sign_in data
        end

        it 'renders a customer list' do
          get '/api/v1/customers'

          assert_response :ok
        end

        it 'renders a customer' do
          get "/api/v1/customers/#{customer.id}"

          assert_response :ok

          json = JSON.parse response.body
          assert_equal customer.id, json['id']
          assert_equal customer.name, json['name']
        end

        it 'creates a new customer' do
          post '/api/v1/customers', params: { name: 'foo' }

          assert_response :created

          json = JSON.parse response.body
          assert json['id']
          assert_equal 'foo', json['name']
        end

        it 'User can destroy customer' do
          klingon = customers :klingon
          delete "/api/v1/customers/#{klingon.id}"

          assert_response :ok

          assert_not_equal klingon, Customer.find_by(id: klingon.id)
        end
      end
    end
  end
end
