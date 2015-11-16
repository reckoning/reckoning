class Invoice < ActiveRecord::Base
  DEFAULT_PAYMENT_DUE_DAYS = 14

  belongs_to :account
  belongs_to :customer
  belongs_to :project
  has_many :positions, dependent: :destroy, inverse_of: :invoice
  has_many :timers, through: :positions

  validates :customer_id, :project_id, :date, presence: true
  validates :ref, uniqueness: { scope: :account_id }

  accepts_nested_attributes_for :positions, allow_destroy: true

  before_validation :set_customer
  before_save :set_rate, :set_value, :set_payment_due_date
  before_create :set_ref

  include Workflow
  workflow do
    state :created do
      event :charge, transitions_to: :charged
    end
    state :charged do
      event :pay, transitions_to: :paid
    end
    state :paid
  end

  def on_charged_entry(_new_state, _event, *_args)
    return unless self.send_via_mail?
    InvoiceMailerWorker.perform_in 1.minute, id
  end

  def on_paid_entry(_new_state, _event, *_args)
    self.pay_date = Time.zone.today
    save
  end

  def self.paid_or_charged
    where(workflow_state: [:charged, :paid])
  end

  def self.paid
    with_paid_state
  end

  def self.charged
    with_charged_state
  end

  def self.due
    where("payment_due_date < ?", Time.zone.now.to_date)
  end

  def self.created
    with_created_state
  end

  def self.year(year)
    where("date <= ? AND date >= ?", "#{year}-12-31", "#{year}-01-01")
  end

  def ref_number
    format "%05d", ref
  end

  def title
    [
      "<b>",
      customer.name,
      "</b> - ",
      project.name
    ].join('').html_safe
  end

  def set_payment_due_date
    return if payment_due_date.present?
    payment_due = customer.payment_due || DEFAULT_PAYMENT_DUE_DAYS
    self.payment_due_date = Time.zone.now + payment_due.days
    save
  end

  def editable?
    !self.state?(:charged) && !self.state?(:paid)
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

  def invoice_file
    "rechnung-#{ref}-#{I18n.l(date.to_date, format: :file).downcase}"
  end

  def timesheet_file
    "stunden-rechnung-#{ref}-#{I18n.l(date.to_date, format: :file).downcase}"
  end

  def pdf
    pdf_options(invoice_file)
  end

  def inline_pdf
    WickedPdf.new.pdf_from_string(
      ApplicationController.new.render_to_string("invoices/pdf", inline_pdf_options),
      whicked_pdf_options
    )
  end

  def timesheet_pdf
    pdf_options(timesheet_file)
  end

  def inline_timesheet_pdf
    WickedPdf.new.pdf_from_string(
      ApplicationController.new.render_to_string("invoices/timesheet", inline_pdf_options),
      whicked_pdf_options
    )
  end

  def pdf_options(file)
    {
      pdf: file
    }.merge(inline_pdf_options).merge(whicked_pdf_options)
  end

  def inline_pdf_options
    {
      layout: "layouts/pdf",
      locals: { resource: self }
    }
  end

  def whicked_pdf_options
    {
      header: {
        content: ApplicationController.new.render_to_string("shared/pdf_header", inline_pdf_options)
      },
      footer: {
        content: ApplicationController.new.render_to_string("shared/pdf_footer", inline_pdf_options)
      },
      margin: {
        top: 30,
        bottom: 42,
        left: 18,
        right: 18
      }
    }
  end

  private def set_customer
    project = Project.find_by(id: project_id)
    customer = Customer.find_by(id: project.customer_id) unless project.blank?
    return if customer.blank?
    self.customer_id = customer.id
  end

  private def set_rate
    self.rate = project.rate
  end

  private def set_ref
    last_invoice = Invoice.where(account_id: account_id).order("ref DESC").first
    if last_invoice.present?
      self.ref = last_invoice.ref + 1
    else
      self.ref = 1
    end
  end
end
