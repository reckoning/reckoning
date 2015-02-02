require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  fixtures :customers, :users

  tests ::CustomersController

  let(:data) { users :data }
  let(:customer) { customers :starfleet }

  describe "unauthorized" do
    it "Unauthrized user cant view customers index" do
      get :index

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view customers new" do
      get :new

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant create new customer" do
      post :create, {customer: {name: "foo"}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view customer edit" do
      get :edit, {id: customer.id}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant destroy customer" do
      delete :destroy, {id: customer.id}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]

      assert_equal customer, Customer.where(id: customer.id).first
    end

    it "Unauthrized user cant update customer" do
      put :update, {id: customer.id, customer: {name: "bar"}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe "happy path" do
    before do
      sign_in data
    end

    it "User can view the customer list" do
      get :index

      assert_response :ok
    end

    it "User can view the new customer page" do
      get :new

      assert_response :ok
    end

    it "User can view the edit customer page" do
      get :edit, {id: customer.id}

      assert_response :ok
    end

    it "User can create a new customer" do
      post :create, {customer: {name: "foo"}}

      assert_response :found
      assert_equal I18n.t(:"messages.customer.create.success"), flash[:notice]
    end

    it "User can update customer" do
      put :update, {id: customer.id, customer: {name: "bar"}}

      assert_response :found
      assert_equal I18n.t(:"messages.customer.update.success"), flash[:notice]
    end

    it "User can destroy customer" do
      klingon = customers :klingon
      delete :destroy, {id: klingon.id}

      assert_response :found

      assert_equal I18n.t(:"messages.customer.destroy.success"), flash[:notice]

      assert_not_equal klingon, Customer.where(id: klingon.id).first
    end
  end

end
