# frozen_string_literal: true

class User < ApplicationRecord
  devise :two_factor_authenticatable, :two_factor_backupable, :confirmable, :lockable, :recoverable,
         :registerable, :rememberable, :trackable, :validatable,
         otp_secret_encryption_key: Rails.application.credentials.devise_otp,
         otp_backup_code_length: 32, otp_number_of_backup_codes: 10

  belongs_to :account
  has_many :timers, dependent: :destroy

  before_save :update_gravatar_hash
  before_create :setup_otp_secret

  validates :email, email: true

  def overtime?
    account.customers.any? { |customer| customer.overtime(id) }
  end

  def weekly_hours
    timers.where('date >= ?', Time.current.beginning_of_week).sum(:value)
  end

  def daily_hours
    timers.where(date: Time.current).sum(:value)
  end

  def update_gravatar_hash
    hash = if gravatar.blank?
             Digest::MD5.hexdigest(id.to_s)
           else
             Digest::MD5.hexdigest(gravatar.downcase.strip)
           end
    self.gravatar_hash = hash
  end

  def setup_otp_secret
    self.otp_secret = User.generate_otp_secret
  end

  def send_welcome
    token = set_reset_password_token
    UserMailer.welcome_mail(self, token).deliver
  end

  def avatar(size = 24)
    "https://www.gravatar.com/avatar/#{gravatar_hash}?s=#{size}&d=https%3A%2F%2Fidenticons.github.com%2F#{gravatar_hash}.png&amp;r=x&amp;s=#{size}"
  end
end
