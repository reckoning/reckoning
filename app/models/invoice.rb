class Invoice < ActiveRecord::Base
  DEFAULT_PAYMENT_DUE_DAYS = 14

  belongs_to :account
  belongs_to :customer
  belongs_to :project
  has_many :positions, dependent: :destroy, inverse_of: :invoice
  has_many :timers, through: :positions

  validates :customer_id, :project_id, :date, presence: true
  validates :ref, uniqueness: true, scope: :account_id

  accepts_nested_attributes_for :positions, allow_destroy: true

  before_validation :set_customer
  before_save :set_rate, :set_value
  before_create :set_ref

  include ::SimpleStates

  # created -> charged -> paid
  states :created, :charged, :paid

  event :charge, from: :created, to: :charged, before: :generate_pdf, after: :send_via_mail
  event :pay, from: :charged, to: :paid, after: :set_pay_date

  def self.paid
    where state: :paid
  end

  def self.charged
    where state: :charged
  end

  def self.due
    where "payment_due_date < ?", Time.now.to_date
  end

  def self.created
    where state: :created
  end

  def self.year(year)
    where("date <= ? AND date >= ?", "#{year}-12-31", "#{year}-01-01")
  end

  def set_pay_date
    self.pay_date = Date.today
    save
  end

  def send_via_mail
    return unless self.send_via_mail?
    InvoiceMailerWorker.perform_in 1.minute, id
  end

  def generate_pdf
    set_payment_due_date
    update_attributes(pdf_generating: true)
    InvoicePdfWorker.perform_async id
  end

  def ref_number
    "%05d".format ref
  end

  def title
    [
      "<b>",
      customer.name,
      "</b> - ",
      project.name
    ].join('').html_safe
  end

  def invoice_file
    "rechnung-#{ref}-#{I18n.l(date.to_date, format: :file).downcase}.pdf"
  end

  def timesheet_file
    "stunden-rechnung-#{ref}-#{I18n.l(date.to_date, format: :file).downcase}.pdf"
  end

  def pdf_path
    path(invoice_file)
  end

  def timesheet_path
    path(timesheet_file)
  end

  def generate
    pdf_generator = InvoicePdfGenerator.new self, pdf_path: pdf_path,
                                                  tempfile: "reckoning-invoice-pdf-#{id}"
    pdf_generator.generate
  end

  def generate_timesheet
    pdf_generator = TimesheetPdfGenerator.new self, pdf_path: timesheet_path,
                                                    tempfile: "reckoning-timesheet-pdf-#{id}"
    pdf_generator.generate
  end

  def set_payment_due_date
    return if payment_due_date.present?
    payment_due = customer.payment_due || DEFAULT_PAYMENT_DUE_DAYS
    self.payment_due_date = Time.now + payment_due.days
    save
  end

  def pdf_present_or_generating?
    self.pdf_present? || self.pdf_generating?
  end

  def pdf_not_present_and_not_generating?
    !self.pdf_present? && !self.pdf_generating?
  end

  def timesheet_not_present_or_generating?
    !self.timesheet_present? || self.pdf_generating?
  end

  def pdf_not_present_or_generating?
    !self.pdf_present? || self.pdf_generating?
  end

  def pdf_present_and_up_to_date?
    self.pdf_present? && (self.pdf_up_to_date? || self.paid?)
  end

  def timesheet_present_and_up_to_date?
    self.timesheet_present? && (self.pdf_up_to_date? || self.paid?)
  end

  def pdf_up_to_date?
    Time.at(pdf_generated_at.to_i) == Time.at(updated_at.to_i)
  end

  def pdf_present?
    File.exist?(pdf_path)
  end

  def timesheet_present?
    File.exist?(timesheet_path)
  end

  def pdf_generating?
    pdf_generating
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

  def files_present?
    !pdf_not_present_or_generating? && (!timesheet_not_present_or_generating? || timers.blank?)
  end

  private

  def path(filename)
    dir = Rails.root.join('files', 'invoices')
    Dir.mkdir(dir) unless File.exist?(dir)
    pdf_dir = dir.join(customer.id.to_s)
    Dir.mkdir(pdf_dir) unless File.exist?(pdf_dir)
    Rails.root.join(pdf_dir, filename).to_s
  end

  def set_customer
    project = Project.where(id: project_id).first
    customer = Customer.where(id: project.customer_id).first unless project.blank?
    return if customer.blan?
    self.customer_id = customer.id
  end

  def set_rate
    self.rate = project.rate
  end

  def set_ref
    last_invoice = Invoice.where(account_id: account_id).order("ref DESC").first
    if last_invoice.present?
      self.ref = last_invoice.ref + 1
    else
      self.ref = 1
    end
  end
end
