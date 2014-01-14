require 'test_helper'

class InvoicesControllerTest < ActionController::TestCase
  tests ::InvoicesController

  def setup
    @user = create(:user)
    @project = create(:project)
    @invoice = create(:invoice, user_id: @user.id)
  end

  def tear_down
    User.delete_all
    Invoice.delete_all
    Customer.delete_all
    Project.delete_all
  end

  test "User can view the dashboard" do
    sign_in @user

    get :index

    assert_response :ok
  end

  test "Unauthrized user cant view invoices index" do
    get :index

    assert_response :found
    assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
  end

  test "User can view the new invoice page" do
    sign_in @user

    get :new

    assert_response :ok
  end

  test "Unauthrized user cant view invoices new" do
    get :new

    assert_response :found
    assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
  end

  test "User can create a new invoice" do
    sign_in @user
    post :create, {invoice: {project_id: @project.id, date: Date.today}}

    assert_response :found
    assert_equal I18n.t(:"messages.create.success", resource: I18n.t(:"resources.messages.invoice")), flash[:notice]
  end

  test "Unauthrized user cant create new invoice" do
    post :create, {invoice: {project_id: @project.id, date: Date.today}}

    assert_response :found
    assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
  end

  test "User can view the edit invoice page" do
    sign_in @user
    get :edit, {ref: @invoice.ref}

    assert_response :ok
  end

  test "Unauthrized user cant view invoice edit" do
    get :edit, {ref: @invoice.ref}

    assert_response :found
    assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
  end

  test "User can update invoice" do
    sign_in @user

    put :update, {ref: @invoice.ref, invoice: {project_id: @project.id, date: Date.today - 1}}

    assert_response :found
    assert_equal I18n.t(:"messages.update.success", resource: I18n.t(:"resources.messages.invoice")), flash[:notice]
  end

  test "Unauthrized user cant update invoice" do
    put :update, {ref: @invoice.ref, invoice: {project_id: @project.id, date: Date.today - 1}}

    assert_response :found
    assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
  end

  test "User can destroy invoice" do
    sign_in @user

    delete :destroy, {ref: @invoice.ref}

    assert_response :found
    assert_equal I18n.t(:"messages.destroy.success", resource: I18n.t(:"resources.messages.invoice")), flash[:notice]

    assert_not_equal @invoice, Invoice.where(id: @invoice.id).first
  end

  test "Unauthrized user cant destroy invoice" do
    delete :destroy, {ref: @invoice.ref}

    assert_response :found
    assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]

    assert_equal @invoice, Invoice.where(id: @invoice.id).first
  end
end
