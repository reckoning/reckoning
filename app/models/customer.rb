class Customer < ActiveRecord::Base
  belongs_to :user
  has_many :projects, dependent: :destroy
  has_many :invoices, dependent: :destroy

  store_accessor :contact_information, :name, :company, :address, :country, :email, :telefon, :fax, :website

  validate :at_least_one_name

  def at_least_one_name
    if self.name.blank? && self.company.blank?
      errors[:name] << I18n.t(:"activerecord.errors.models.invoice.attributes.company_name.empty")
      errors[:company] << I18n.t(:"activerecord.errors.models.invoice.attributes.company_name.empty")
    end
  end

  def fullname
    company_and_name = []
    company_and_name << name if name.present?
    company_and_name << company if company.present?
    company_and_name.join(' | ')
  end
end
