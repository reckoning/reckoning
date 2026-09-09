# frozen_string_literal: true

require "test_helper"

# The paths the SPA took over still answer, because bookmarks and the links
# on the screens that have not moved yet point at them. What they carry
# matters as much as where they lead: a filtered list, a project preselected
# for a new invoice and the screen to return to after signing in all travel
# in the query string, which `redirect("/app/…")` drops on the floor.
class SpaCutoverLinksTest < ActionDispatch::IntegrationTest
  let(:id) { "aaaaaaaa-0000-4000-8000-000000000001" }

  it "keeps a list's filters" do
    get "/projects?state=archived"
    assert_redirected_to "/app/projects?state=archived"

    get "/invoices?year=2026&state=paid"
    assert_redirected_to "/app/invoices?year=2026&state=paid"

    get "/offers?year=2026"
    assert_redirected_to "/app/offers?year=2026"
  end

  # `projects/show` links a new invoice for the project it is showing, and
  # the form reads the project out of the query.
  it "keeps the project a new invoice is for" do
    get "/invoices/new?project_id=#{id}"
    assert_redirected_to "/app/invoices/new?project_id=#{id}"

    get "/offers/new?project_id=#{id}"
    assert_redirected_to "/app/offers/new?project_id=#{id}"
  end

  it "keeps the screen to come back to after signing in" do
    get "/signin?return=%2Fsettings"
    assert_redirected_to "/app/login?return=%2Fsettings"
  end

  it "carries a record's id into its own screen" do
    get "/invoices/#{id}"
    assert_redirected_to "/app/invoices/#{id}"

    get "/invoices/#{id}/edit"
    assert_redirected_to "/app/invoices/#{id}/edit"

    get "/offers/#{id}"
    assert_redirected_to "/app/offers/#{id}"

    get "/offers/#{id}/edit"
    assert_redirected_to "/app/offers/#{id}/edit"

    get "/customers/#{id}/edit"
    assert_redirected_to "/app/customers/#{id}/edit"

    get "/projects/#{id}/edit"
    assert_redirected_to "/app/projects/#{id}/edit"
  end

  it "leads to the screen itself where there is nothing to carry" do
    get "/projects/new"
    assert_redirected_to "/app/projects/new"

    get "/timesheet"
    assert_redirected_to "/app/timesheet"
  end
end
