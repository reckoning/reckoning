# frozen_string_literal: true

require "test_helper"

# Every project screen is the SPA's now. What is left here is the handover
# for the paths the rest of the app links.
class ProjectsControllerTest < ActionDispatch::IntegrationTest
  let(:will) { users :will }
  let(:project) { projects :narendra3 }

  describe "the paths that moved" do
    before { sign_in will }

    it "sends the list to the spa" do
      get "/projects"

      assert_redirected_to "/app/projects"
    end

    it "sends the new form to the spa" do
      get "/projects/new"

      assert_redirected_to "/app/projects/new"
    end

    it "sends the edit form to the spa" do
      get "/projects/#{project.id}/edit"

      assert_redirected_to "/app/projects/#{project.id}/edit"
    end

    # The panels around the app link a project, and so does the dashboard.
    it "sends a project to the spa" do
      get "/projects/#{project.id}"

      assert_redirected_to "/app/projects/#{project.id}"
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
