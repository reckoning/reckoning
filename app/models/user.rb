include HstoreAccessor

class User < ActiveRecord::Base
  devise :database_authenticatable, :confirmable, :lockable, :recoverable, :registerable, :rememberable, :trackable, :validatable

  store_accessor :settings, :tax, :tax_ref
	store_accessor :bank_account, :bank, :account_number, :bank_code, :iban, :bic

  has_one :address, as: :resource, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :projects, through: :customers, dependent: :destroy

  accepts_nested_attributes_for :address

  delegate :company, :name, :contact,
    to: :address, prefix: false, allow_nil: true

  before_save :update_gravatar_hash

  def update_gravatar_hash
    if gravatar.blank?
      hash = Digest::MD5.hexdigest(id.to_s)
    else
      hash = Digest::MD5.hexdigest(gravatar.downcase.strip)
    end
    self.gravatar_hash = hash
  end

end
