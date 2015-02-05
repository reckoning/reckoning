class Account < ActiveRecord::Base
  has_many :users
  has_many :invoices, dependent: :destroy
  has_many :positions, through: :invoices
  has_many :weeks, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :projects, through: :customers
  has_many :tasks, through: :projects
  has_many :timers, through: :tasks

  store_accessor :settings, :tax, :tax_ref, :provision
  store_accessor :bank_account, :bank, :account_number, :bank_code, :iban, :bic
  store_accessor :services, :dropbox_user, :dropbox_token
  store_accessor :mailing, :default_from, :signature
  store_accessor :contact_information, :address, :country, :public_email, :telefon, :fax, :website

  validates :name, presence: true
  validates :subdomain, uniqueness: true, allow_nil: true

  def dropbox?
    dropbox_token.present?
  end
end
