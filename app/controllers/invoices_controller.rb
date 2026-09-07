# frozen_string_literal: true

class InvoicesController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav

  def pdf
    authorize! :read, invoice
    respond_to do |format|
      format.pdf do
        send_data invoice.inline_pdf, filename: "#{invoice.invoice_file}.pdf", type: "application/pdf", disposition: "inline"
      end
      unless Rails.env.production?
        format.html do
          @resource = invoice
          @preview = true
          render "pdf", layout: "pdf"
        end
      end
    end
  end

  def timesheet
    authorize! :read, invoice
    respond_to do |format|
      format.pdf do
        send_data invoice.inline_timesheet_pdf, filename: "#{invoice.timesheet_file}.pdf", type: "application/pdf", disposition: "inline"
      end
      unless Rails.env.production?
        format.html do
          @resource = invoice
          @preview = true
          render "timesheet_pdf", layout: "pdf"
        end
      end
    end
  end

  private def set_active_nav
    @active_nav = "invoices"
  end

  private def invoice
    @invoice ||= current_account.invoices.find_by(id: params.fetch(:id, nil))
  end
  helper_method :invoice
end
