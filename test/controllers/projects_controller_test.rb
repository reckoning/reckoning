require 'test_helper'

class ProjectsControllerTest < ActionController::TestCase
  tests ::ProjectsController

  let(:user) { create :user }
  let(:customer) { create :customer, user: user }
  let(:project) { create :project, customer: customer }

  describe "unauthorized" do
    it "Unauthrized user cant view projects index" do
      get :index

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view projects new" do
      get :new

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant create new project" do
      post :create, {project: {project_id: "foo", date: Date.today}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view project edit" do
      get :edit, {id: project.id}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant destroy project" do
      delete :destroy, {id: project.id}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]

      assert_equal project, Project.where(id: project.id).first
    end

    it "Unauthrized user cant update project" do
      put :update, {id: project.id, project: {date: Date.today - 1}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe "missing dependencies" do
    let(:user_without_customer) { create :user }

    it "redirects to user edit if address is missing" do
      sign_in user_without_customer

      get :new

      assert_response :found

      assert_equal I18n.t(:"messages.project.missing_customer"), flash[:alert]
    end
  end

  describe "happy path" do
    before do
      sign_in user
      customer
    end

    it "User can view the project list" do
      get :index

      assert_response :ok
    end

    it "User can view the new project page" do
      get :new

      assert_response :ok
    end

    it "User can view the edit project page" do
      get :edit, {id: project.id}

      assert_response :ok
    end

    it "User can create a new project" do
      post :create, {project: {customer_id: customer.id, name: "foo"}}

      assert_response :found
      assert_equal I18n.t(:"messages.project.create.success"), flash[:notice]
    end

    it "User can update project" do
      put :update, {id: project.id, project: {name: "bar"}}

      assert_response :found
      assert_equal I18n.t(:"messages.project.update.success"), flash[:notice]
    end

    it "User can destroy project" do
      delete :destroy, {id: project.id}

      assert_response :found
      assert_equal I18n.t(:"messages.project.destroy.success"), flash[:notice]

      assert_not_equal project, Project.where(id: project.id).first
    end
  end

end