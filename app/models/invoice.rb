class Invoice < ActiveRecord::Base
  DEFAULT_PAYMENT_DUE_DAYS = 14

  belongs_to :account
  belongs_to :customer
  belongs_to :project
  has_many :positions, dependent: :destroy, inverse_of: :invoice
  has_many :timers, through: :positions

  validates_presence_of :customer_id, :project_id, :date
  validates_uniqueness_of :ref, scope: :account_id

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

  def self.year year
    where "date <= ? AND date >= ?", "#{year}-12-31", "#{year}-01-01"
  end

  def set_pay_date
    self.pay_date = Date.today
    self.save
  end

  def send_via_mail
    if self.send_via_mail?
      InvoiceMailerWorker.perform_in 1.minute, self.id
    end
  end

  def generate_pdf
    self.set_payment_due_date
    self.update_attributes({pdf_generating: true})
    InvoicePdfWorker.perform_async self.id
  end

  def ref_number
    "%05d" % self.ref
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
    "rechnung-#{self.ref}-#{I18n.l(self.date.to_date, format: :file).downcase}.pdf"
  end

  def timesheet_file
    "stunden-rechnung-#{self.ref}-#{I18n.l(self.date.to_date, format: :file).downcase}.pdf"
  end

  def pdf_path
    path(invoice_file)
  end

  def timesheet_path
    path(timesheet_file)
  end

  def generate
    pdf_generator = InvoicePdfGenerator.new self, {
      pdf_path: pdf_path,
      tempfile: "reckoning-invoice-pdf-#{self.id}"
    }
    pdf_generator.generate
  end

  def generate_timesheet
    pdf_generator = TimesheetPdfGenerator.new self, {
      pdf_path: timesheet_path,
      tempfile: "reckoning-timesheet-pdf-#{self.id}"
    }
    pdf_generator.generate
  end

  def set_payment_due_date
    if self.payment_due_date.blank?
      payment_due = self.customer.payment_due || DEFAULT_PAYMENT_DUE_DAYS
      self.payment_due_date = Time.now + payment_due.days
      self.save
    end
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
    Time.at(self.pdf_generated_at.to_i) == Time.at(self.updated_at.to_i)
  end

  def pdf_present?
    File.exists?(pdf_path)
  end

  def timesheet_present?
    File.exists?(timesheet_path)
  end

  def pdf_generating?
    self.pdf_generating
  end

  def editable?
    !self.state?(:charged) && !self.state?(:paid)
  end

  def set_value
    value = 0.0
    self.positions.each do |position|
      unless position.marked_for_destruction?
        if position.value.present?
          value = value + position.value
        elsif position.hours && position.rate
          value = value + (position.rate * position.hours)
        end
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
    Dir.mkdir(dir) unless File.exists?(dir)
    pdf_dir = dir.join(self.customer.id.to_s)
    Dir.mkdir(pdf_dir) unless File.exists?(pdf_dir)
    Rails.root.join(pdf_dir, filename).to_s
  end

  def set_customer
    project = Project.where(id: project_id).first
    customer = Customer.where(id: project.customer_id).first unless project.blank?
    if customer.present?
      self.customer_id = customer.id
    end
  end

  def set_rate
    self.rate = self.project.rate
  end

  def set_ref
    last_invoice = Invoice.where(account_id: self.account_id).order("ref DESC").first
    if last_invoice.present?
      self.ref = last_invoice.ref + 1
    else
      self.ref = 1
    end
  end
end
