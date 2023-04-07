# frozen_string_literal: true

class Offer < ApplicationRecord
  include AASM
  include PdfOptions
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::OutputSafetyHelper

  belongs_to :account
  belongs_to :customer
  belongs_to :project
  has_many :positions, class_name: "OfferPosition", foreign_key: :invoicable_id, dependent: :destroy, inverse_of: :invoicable

  validates :date, presence: true
  validates :ref, uniqueness: {scope: :account_id}

  accepts_nested_attributes_for :positions, allow_destroy: true

  before_validation :set_customer
  before_save :set_rate, :set_value
  before_create :set_ref

  aasm timestamps: true do
    state :created, initial: true
    state :bided
    state :accepted
    state :declined
    state :canceled

    event :bid do
      transitions from: :created, to: :bided
      transitions from: :declined, to: :bided
      transitions from: :canceled, to: :bided
    end

    event :accept do
      transitions from: :bided, to: :accepted
    end

    event :decline do
      transitions from: :bided, to: :declined
    end

    event :cancel do
      transitions from: :bided, to: :canceled
    end
  end

  def self.year(year)
    where("date <= ? AND date >= ?", "#{year}-12-31", "#{year}-01-01")
  end

  def self.filter_result(filter_params)
    filter_year(filter_params.fetch(:year, nil))
      .filter_state(filter_params.fetch(:state, nil))
  end

  def self.filter_year(year)
    return all if year.blank? || year !~ /\d{4}/

    year(year)
  end

  def self.filter_state(state)
    return all if state.blank? || Invoice.workflow_spec.state_names.exclude?(state.to_sym)

    send(state)
  end

  def ref_number
    format "%05d", ref
  end

  def title
    output = []
    output << tag.strong(customer.name)
    output << " - "
    output << project.name
    safe_join(output)
  end

  def editable?
    !bided? && !accepted?
  end

  def set_value
    value = 0.0
    positions.each do |position|
      next if position.marked_for_destruction?

      if position.value.present?
        value += position.value
      elsif position.hours && position.rate
        value += (position.rate * position.hours)
      end
    end
    self.value = value
  end

  def send_via_mail?
    customer.email_template.present? && customer.invoice_email.present?
  end

  def offer_file
    "offer-#{ref}-#{I18n.l(date.to_date, format: :file).downcase}"
  end

  def pdf
    pdf_options(offer_file)
  end

  def inline_pdf
    WickedPdf.new.pdf_from_string(
      ApplicationController.new.render_to_string("offers/pdf", inline_pdf_options),
      whicked_pdf_options
    )
  end

  private def set_customer
    project = Project.find_by(id: project_id)
    customer = Customer.find_by(id: project.customer_id) if project.present?
    return if customer.blank?

    self.customer_id = customer.id
  end

  private def set_rate
    self.rate = project.rate
  end

  private def set_ref
    last_offer = Offer.where(account_id: account_id).order("ref DESC").first
    self.ref = if last_offer.present?
      last_offer.ref + 1
    else
      1
    end
  end
end
