require 'test_helper'

class CustomersControllerTest < ActionController::TestCase
  fixtures :customers, :users

  tests ::CustomersController

  let(:data) { users :data }
  let(:customer) { customers :starfleet }

  describe "unauthorized" do
    it "Unauthrized user cant view customer edit" do
      get :edit, id: customer.id

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant update customer" do
      put :update, id: customer.id, customer: { name: "bar" }

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe "happy path" do
    before do
      sign_in data
    end

    it "User can view the edit customer page" do
      get :edit, id: customer.id

      assert_response :ok
    end

    it "User can update customer" do
      put :update, id: customer.id, customer: { name: "bar" }

      assert_response :found
      assert_equal I18n.t(:"resources.messages.update.success", resource: I18n.t(:"resources.customer")), flash[:success]
    end
  end
end
