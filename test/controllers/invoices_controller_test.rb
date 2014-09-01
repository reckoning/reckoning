require 'test_helper'

class InvoicesControllerTest < ActionController::TestCase
  tests ::InvoicesController

  let(:user) { create :user }
  let(:customer) { create :customer, user: user }
  let(:project) { create :project, customer: customer }
  let(:invoice) { create :invoice, project: project, customer: customer, user: user }

  describe "unauthorized" do
    it "Unauthrized user cant view invoices index" do
      get :index

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view invoices new" do
      get :new

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant create new invoice" do
      post :create, {invoice: {project_id: "foo", date: Date.today}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view invoice edit" do
      get :edit, {ref: invoice.ref}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant destroy invoice" do
      delete :destroy, {ref: invoice.ref}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]

      assert_equal invoice, Invoice.where(id: invoice.id).first
    end

    it "Unauthrized user cant update invoice" do
      put :update, {ref: invoice.ref, invoice: {date: Date.today - 1}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe "missing dependencies" do
    let(:user_without_address) { create :user, :without_address }

    it "redirects to user edit if address is missing" do
      sign_in user_without_address

      get :new

      assert_response :found

      assert_equal I18n.t(:"messages.invoice.missing_address"), flash[:alert]
    end
  end

  describe "happy path" do
    before do
      sign_in user
    end

    it "User can view the invoice list" do
      get :index

      assert_response :ok
    end

    it "User can view the new invoice page" do
      get :new

      assert_response :ok
    end

    it "User can view the edit invoice page" do
      get :edit, {ref: invoice.ref}

      assert_response :ok
    end

    it "User can create a new invoice" do
      post :create, {invoice: {project_id: project.id, date: Date.today}}

      assert_response :found
      assert_equal I18n.t(:"messages.invoice.create.success"), flash[:notice]
    end

    it "User can update invoice" do
      put :update, {ref: invoice.ref, invoice: {project_id: project.id, date: Date.today - 1}}

      assert_response :found
      assert_equal I18n.t(:"messages.invoice.update.success"), flash[:notice]
    end

    it "User can destroy invoice" do
      delete :destroy, {ref: invoice.ref}

      assert_response :found
      assert_equal I18n.t(:"messages.invoice.destroy.success"), flash[:notice]

      assert_not_equal invoice, Invoice.where(id: invoice.id).first
    end
  end

end
