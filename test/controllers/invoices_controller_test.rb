# frozen_string_literal: true

require "test_helper"

# The invoice screens are the SPA's since phase B6. What the server still owns
# is the handover, the PDFs — which the migration plan keeps server-rendered
# on purpose — and `send_test_mail`, because the *offers* form posts to it.
class InvoicesControllerTest < ActionDispatch::IntegrationTest
  let(:data) { users :data }
  let(:invoice) { invoices :january }

  describe "the paths that moved" do
    it "serves the list from the shell" do
      get "/invoices"

      assert_response :success
      assert_select "div#spa"
    end

    # A filtered, sorted link has to survive the handover, or every bookmark
    # and every redirect after an action lands on an unfiltered page.
    it "serves a filtered list from the shell" do
      get "/invoices?state=paid&sort=value&direction=asc"

      assert_response :success
      assert_select "div#spa"
    end

    it "serves the detail page from the shell" do
      get "/invoices/#{invoice.id}"

      assert_response :success
      assert_select "div#spa"
    end

    # Declared before the resource's member routes for this reason: behind
    # them, `:id` matches "new" and the form is unreachable.
    it "serves the new form from the shell, project and all" do
      get "/invoices/new?project_id=#{projects(:narendra3).id}"

      assert_response :success
      assert_select "div#spa"
    end

    it "serves the edit form from the shell" do
      get "/invoices/#{invoice.id}/edit"

      assert_response :success
      assert_select "div#spa"
    end
  end

  describe "what the server still answers" do
    before { sign_in data }

    it "serves the invoice pdf" do
      get "/invoices/#{invoice.id}/pdf/#{invoice.invoice_file}.pdf"

      assert_response :success
      assert_equal "application/pdf", response.media_type
    end

    # The test mail moved to /api/v1 with the detail page. The one ERB form
    # that posted here — the offers one — was never rendered by any view.
    it "no longer takes a test mail" do
      post "/invoices/#{invoice.id}/send_test_mail", params: {test_mail: {email: "picard@star.fleet"}}

      assert_response :not_found
    end
  end

  describe "the writes that moved to the api" do
    before { sign_in data }

    it "no longer answers create, update, charge, pay or destroy" do
      post "/invoices", params: {invoice: {ref: 42}}
      assert_response :not_found

      patch "/invoices/#{invoice.id}", params: {invoice: {ref: 42}}
      assert_response :not_found

      put "/invoices/#{invoice.id}/charge"
      assert_response :not_found

      delete "/invoices/#{invoice.id}"
      assert_response :not_found

      assert_equal 1, invoice.reload.ref
    end
  end
end
