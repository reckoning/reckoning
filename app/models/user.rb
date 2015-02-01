class User < ActiveRecord::Base
  devise :database_authenticatable, :confirmable, :lockable, :recoverable, :registerable, :rememberable, :trackable, :validatable

  store_accessor :settings, :tax, :tax_ref, :provision
	store_accessor :bank_account, :bank, :account_number, :bank_code, :iban, :bic
  store_accessor :services, :dropbox_user, :dropbox_token
  store_accessor :mailing, :default_from, :signature
  store_accessor :contact_information, :name, :company, :address, :country, :public_email, :telefon, :fax, :website

  has_many :invoices, dependent: :destroy
  has_many :positions, through: :invoices
  has_many :weeks, dependent: :destroy
  has_many :customers, dependent: :destroy
  has_many :projects, through: :customers
  has_many :tasks, through: :projects
  has_many :timers, through: :tasks

  before_save :update_gravatar_hash
  before_save :ensure_authentication_token

  validates_format_of :email, with: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

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

  def has_dropbox?
    self.dropbox_token.present?
  end

  def send_welcome
    token = set_reset_password_token
    UserMailer.welcome_mail(self, token).deliver
  end

  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.where(authentication_token: token).first
    end
  end
end
