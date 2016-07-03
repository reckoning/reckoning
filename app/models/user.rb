# encoding: utf-8
# frozen_string_literal: true
class User < ActiveRecord::Base
  devise :two_factor_authenticatable, :two_factor_backupable, :confirmable, :lockable, :recoverable,
         :registerable, :rememberable, :trackable, :validatable,
         otp_secret_encryption_key: Rails.application.secrets[:devise_otp],
         otp_backup_code_length: 32, otp_number_of_backup_codes: 10

  belongs_to :account
  has_many :timers

  before_save :update_gravatar_hash
  before_save :ensure_authentication_token
  before_create :setup_otp_secret

  validates :email, email: true

  def update_gravatar_hash
    hash = if gravatar.blank?
             Digest::MD5.hexdigest(id.to_s)
           else
             Digest::MD5.hexdigest(gravatar.downcase.strip)
           end
    self.gravatar_hash = hash
  end

  def ensure_authentication_token
    return if authentication_token.present?
    self.authentication_token = generate_authentication_token
  end

  def setup_otp_secret
    self.otp_secret = User.generate_otp_secret
  end

  def send_welcome
    token = set_reset_password_token
    UserMailer.welcome_mail(self, token).deliver
  end

  private def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless User.find_by(authentication_token: token)
    end
  end
end
