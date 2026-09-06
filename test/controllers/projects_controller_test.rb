# frozen_string_literal: true

require "test_helper"

# The list and the form are the SPA's since phase B3. What is left here is the
# detail page — it renders the offers and invoices panels, which belong to B6
# and B7 — plus the handover for the paths that moved.
class ProjectsControllerTest < ActionDispatch::IntegrationTest
  let(:will) { users :will }
  let(:project) { projects :narendra3 }

  describe "the paths that moved" do
    it "sends the list to the spa" do
      sign_in will

      get "/projects"

      assert_redirected_to "/app/projects"
    end

    it "sends the new form to the spa" do
      sign_in will

      get "/projects/new"

      assert_redirected_to "/app/projects/new"
    end

    it "sends the edit form to the spa" do
      sign_in will

      get "/projects/#{project.id}/edit"

      assert_redirected_to "/app/projects/#{project.id}/edit"
    end

    # The SPA writes through the API, so the routes the ERB forms posted to
    # are gone rather than left dangling.
    it "no longer answers create or update" do
      sign_in will

      post "/projects", params: {project: {name: "Wolf 359"}}
      assert_response :not_found

      patch "/projects/#{project.id}", params: {project: {name: "Wolf 359"}}
      assert_response :not_found

      assert_equal "Narendra 3", project.reload.name
    end
  end

  describe "the detail page" do
    it "is unreachable when signed out" do
      get "/projects/#{project.id}"

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "renders for the account it belongs to" do
      sign_in will

      get "/projects/#{project.id}"

      assert_response :ok
    end
  end
end
