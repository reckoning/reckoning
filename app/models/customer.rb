class Customer < ActiveRecord::Base
  belongs_to :user
  has_many :projects, dependent: :destroy
  has_many :invoices, dependent: :destroy

  store_accessor :contact_information, :address, :country, :email, :telefon, :fax, :website

  validates_presence_of :name
  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, allow_blank: true
end
