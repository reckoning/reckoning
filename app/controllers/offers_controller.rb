# frozen_string_literal: true

class OffersController < ApplicationController
  include ResourceHelper

  before_action :set_active_nav

  def pdf
    authorize! :read, offer
    respond_to do |format|
      format.pdf do
        send_data offer.inline_pdf, filename: "#{offer.offer_file}.pdf", type: "application/pdf", disposition: "inline"
      end
      unless Rails.env.production?
        format.html do
          render "pdf", layout: "pdf", locals: {resource: offer}
        end
      end
    end
  end

  private def set_active_nav
    @active_nav = "offers"
  end

  private def offer
    @offer ||= current_account.offers.find_by(id: params.fetch(:id, nil))
  end
  helper_method :offer
end
