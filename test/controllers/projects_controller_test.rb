# frozen_string_literal: true

require "test_helper"

# Every project screen is the SPA's now. What is left here is the handover
# for the paths the rest of the app links.
class ProjectsControllerTest < ActionDispatch::IntegrationTest
  let(:will) { users :will }
  let(:project) { projects :narendra3 }

  describe "the paths that moved" do
    before { sign_in will }

    it "serves the list from the shell" do
      get "/projects"

      assert_response :success
      assert_select "div#spa"
    end

    it "serves the new form from the shell" do
      get "/projects/new"

      assert_response :success
      assert_select "div#spa"
    end

    it "serves the edit form from the shell" do
      get "/projects/#{project.id}/edit"

      assert_response :success
      assert_select "div#spa"
    end

    # The panels around the app link a project, and so does the dashboard.
    it "serves a project from the shell" do
      get "/projects/#{project.id}"

      assert_response :success
      assert_select "div#spa"
    end

    # The SPA writes through the API, so the routes the ERB forms posted to
    # are gone rather than left dangling.
    it "no longer answers create or update" do
      post "/projects", params: {project: {name: "Wolf 359"}}
      assert_response :not_found

      patch "/projects/#{project.id}", params: {project: {name: "Wolf 359"}}
      assert_response :not_found

      assert_equal "Narendra 3", project.reload.name
    end
  end
end
