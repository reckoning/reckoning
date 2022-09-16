# frozen_string_literal: true

module OffersHelper
  def offer_label(offer)
    case offer.aasm_state.to_s
    when 'created'
      'default'
    when 'paid'
      'success'
    else
      'primary'
    end
  end

  def first_offer_year
    first_offer = current_account.offers.order('date').first
    return if first_offer.blank?

    first_offer.date.year
  end

  def current_offer_years
    current_year = Time.zone.now.year
    current_year = 1.year.from_now.year if Time.zone.now.month == 12
    years = if first_invoice_year
              (first_invoice_year..current_year)
            else
              (1.year.ago.year..current_year)
            end
    years.to_a.reverse.map do |year|
      { name: year, link: year }
    end
  end
end
