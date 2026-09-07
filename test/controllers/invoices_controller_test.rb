# frozen_string_literal: true

require "test_helper"

class InvoicesControllerTest < ActionDispatch::IntegrationTest
  let(:invoice) { invoices :january }

  describe "unauthorized" do
    # The list is the SPA's since phase B6. The path still resolves — the
    # navigation links it and so do the redirects after charging or paying —
    # and the SPA's own guard decides who gets in.
    it "sends the list to the spa, signed in or not" do
      get "/invoices"

      assert_redirected_to "/app/invoices"
    end

    it "Unauthrized user cant view invoices new" do
      get "/invoices/new"

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant create new invoice" do
      post "/invoices", params: {invoice: {project_id: "foo", date: Time.zone.today}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant view invoice edit" do
      get "/invoices/#{invoice.id}/edit"

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end

    it "Unauthrized user cant destroy invoice" do
      delete "/invoices/#{invoice.id}"

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]

      assert_equal invoice, Invoice.where(id: invoice.id).first
    end

    it "Unauthrized user cant update invoice" do
      put "/invoices/#{invoice.id}", params: {invoice: {date: Time.zone.today - 1}}

      assert_response :found
      assert_equal I18n.t(:"devise.failure.unauthenticated"), flash[:alert]
    end
  end

  describe "missing dependencies" do
    let(:worf) { users :worf }
    it "redirects to user edit if address is missing" do
      sign_in worf

      get "/invoices/new"

      assert_response :found

      assert_equal I18n.t(:"messages.missing_address"), flash[:alert]
    end
  end

  describe "happy path" do
    let(:data) { users :data }
    before do
      sign_in data
    end

    it "sends the list to the spa" do
      get "/invoices"

      assert_redirected_to "/app/invoices"
    end

    it "sends the detail page to the spa" do
      get "/invoices/#{invoice.id}"

      assert_redirected_to "/app/invoices/#{invoice.id}"
    end

    # The redirect is declared after the resource for this reason: ahead of it,
    # `:id` matches "new" and the form becomes unreachable.
    it "still serves the new form rather than treating it as an id" do
      get "/invoices/new"

      assert_response :ok
    end

    # A filtered, sorted link has to survive the handover, or every bookmark
    # and every redirect after an action lands on an unfiltered page.
    it "carries the query into the spa" do
      get "/invoices?state=paid&sort=value&direction=asc"

      assert_redirected_to "/app/invoices?state=paid&sort=value&direction=asc"
    end

    it "User can view the new invoice page" do
      get "/invoices/new"

      assert_response :ok
    end

    it "User can view the edit invoice page" do
      get "/invoices/#{invoice.id}/edit"

      assert_response :ok
    end

    it "User can create a new invoice" do
      post "/invoices", params: {invoice: {project_id: invoice.project.id, date: Time.zone.today}}

      assert_response :found
      assert_equal I18n.t(:"resources.messages.create.success", resource: I18n.t(:"resources.invoice")), flash[:success]
    end

    it "User can update invoice" do
      put "/invoices/#{invoice.id}", params: {invoice: {project_id: invoice.project.id, date: Time.zone.today - 1}}

      assert_response :found
      assert_equal I18n.t(:"resources.messages.update.success", resource: I18n.t(:"resources.invoice")), flash[:success]
    end

    it "User can destroy invoice" do
      delete "/invoices/#{invoice.id}"

      assert_response :found
      assert_equal I18n.t(:"resources.messages.destroy.success", resource: I18n.t(:"resources.invoice")), flash[:success]

      assert_not_equal invoice, Invoice.where(id: invoice.id).first
    end

    it "User can charge an invoice" do
      put "/invoices/#{invoice.id}/charge"

      assert_redirected_to "/"
      assert(invoice.reload.charged?)
    end
  end
end
