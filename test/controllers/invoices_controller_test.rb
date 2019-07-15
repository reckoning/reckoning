# frozen_string_literal: true

require 'test_helper'

class InvoicesControllerTest < ActionController::TestCase
  tests ::InvoicesController

  let(:invoice) { invoices :january }

  describe 'unauthorized' do
    it 'Unauthrized user cant view invoices index' do
      get :index

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it 'Unauthrized user cant view invoices new' do
      get :new

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it 'Unauthrized user cant create new invoice' do
      post :create, params: { invoice: { project_id: 'foo', date: Time.zone.today } }

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it 'Unauthrized user cant view invoice edit' do
      get :edit, params: { id: invoice.id }

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it 'Unauthrized user cant destroy invoice' do
      delete :destroy, params: { id: invoice.id }

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]

      assert_equal invoice, Invoice.where(id: invoice.id).first
    end

    it 'Unauthrized user cant update invoice' do
      put :update, params: { id: invoice.id, invoice: { date: Time.zone.today - 1 } }

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe 'missing dependencies' do
    let(:worf) { users :worf }
    it 'redirects to user edit if address is missing' do
      sign_in worf

      get :new

      assert_response :found

      assert_equal I18n.t(:"messages.missing_address"), flash[:alert]
    end
  end

  describe 'happy path' do
    let(:data) { users :data }
    before do
      sign_in data
    end

    it 'User can view the invoice list' do
      get :index

      assert_response :ok
    end

    it 'User can view the new invoice page' do
      get :new

      assert_response :ok
    end

    it 'User can view the edit invoice page' do
      get :edit, params: { id: invoice.id }

      assert_response :ok
    end

    it 'User can create a new invoice' do
      post :create, params: { invoice: { project_id: invoice.project.id, date: Time.zone.today } }

      assert_response :found
      assert_equal I18n.t(:"resources.messages.create.success", resource: I18n.t(:"resources.invoice")), flash[:success]
    end

    it 'User can update invoice' do
      put :update, params: { id: invoice.id, invoice: { project_id: invoice.project.id, date: Time.zone.today - 1 } }

      assert_response :found
      assert_equal I18n.t(:"resources.messages.update.success", resource: I18n.t(:"resources.invoice")), flash[:success]
    end

    it 'User can destroy invoice' do
      delete :destroy, params: { id: invoice.id }

      assert_response :found
      assert_equal I18n.t(:"resources.messages.destroy.success", resource: I18n.t(:"resources.invoice")), flash[:success]

      assert_not_equal invoice, Invoice.where(id: invoice.id).first
    end

    it 'User can charge an invoice' do
      @request.env['HTTP_REFERER'] = 'where_i_came_from'
      put :charge, params: { id: invoice.id }

      assert_redirected_to 'where_i_came_from'
      assert invoice.reload.charged?, invoice.inspect
    end
  end
end
