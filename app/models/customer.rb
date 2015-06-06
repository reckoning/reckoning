class Customer < ActiveRecord::Base
  belongs_to :account
  has_many :projects, dependent: :destroy
  has_many :invoices, dependent: :destroy

  store_accessor :contact_information, :address, :country, :email, :telefon, :fax, :website

  validates :name, presence: true
  validates :email, email: true
end
