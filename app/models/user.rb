include HstoreAccessor

class User < ActiveRecord::Base
  devise :database_authenticatable, :confirmable, :lockable, :recoverable, :registerable, :rememberable, :trackable, :validatable

  store_accessor :settings, :tax, :tax_ref
	store_accessor :bank_account, :bank, :account_number, :bank_code, :iban, :bic

  has_one :address, as: :resource, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_many :positions, through: :invoices
  has_many :weeks, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :projects, through: :customers
  has_many :tasks
  has_many :timers, through: :tasks

  accepts_nested_attributes_for :address

  delegate :company, :name, :contact,
    to: :address, prefix: false, allow_nil: true

  before_save :update_gravatar_hash
  before_save :ensure_authentication_token

  def update_gravatar_hash
    if gravatar.blank?
      hash = Digest::MD5.hexdigest(id.to_s)
    else
      hash = Digest::MD5.hexdigest(gravatar.downcase.strip)
    end
    self.gravatar_hash = hash
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
