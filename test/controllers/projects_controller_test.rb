# frozen_string_literal: true

require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  let(:project) { projects :narendra3 }

  describe "unauthorized" do
    it "Unauthrized user cant view projects index" do
      get "/projects"

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view projects new" do
      get "/projects/new"

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant create new project" do
      post "/projects", params: {project: {project_id: "foo", date: Time.zone.today}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view project edit" do
      get "/projects/#{project.id}/edit"

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant update project" do
      put "/projects/#{project.id}", params: {project: {date: Time.zone.today - 1}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe "missing dependencies" do
    let(:worf) { users :worf }

    it "redirects to user edit if address is missing" do
      sign_in worf

      get "/projects/new"

      assert_response :found

      assert_equal I18n.t(:"messages.missing_address"), flash[:alert]
    end
  end

  describe "happy path" do
    let(:will) { users :will }
    let(:outpost6) { projects :outpost6 }

    before do
      sign_in will
    end

    it "User can view the project list" do
      get "/projects"

      assert_response :ok
    end

    it "User can view the new project page" do
      get "/projects/new"

      assert_response :ok
    end

    it "User can view the edit project page" do
      get "/projects/#{project.id}/edit"

      assert_response :ok
    end

    it "User can create a new project" do
      post "/projects", params: {project: {customer_id: project.customer.id, name: "foo"}}

      assert_response :found
      assert_equal I18n.t(:"resources.messages.create.success", resource: I18n.t(:"resources.project")), flash[:success]
    end

    it "User can update project" do
      put "/projects/#{project.id}", params: {project: {name: "bar"}}

      assert_response :found
      assert_equal I18n.t(:"resources.messages.update.success", resource: I18n.t(:"resources.project")), flash[:success]
    end
  end
end
