# encoding: utf-8
# frozen_string_literal: true
require "json_web_token"

class AuthToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true

  before_validation :generate_authentication_token, on: :create

  def self.system
    where(scope: "system")
  end

  def self.not_expired
    where("? < expires", Time.zone.now.to_i)
  end

  def system?
    scope == "system"
  end

  private def generate_authentication_token
    # System Tokens should expire after 24 hours
    self.expires = Time.zone.now.to_i + (24 * 3600) if system?
    loop do
      auth_token = Devise.friendly_token
      next if AuthToken.find_by(user_id: user_id, token: auth_token)

      payload = {
        token: auth_token,
        user_id: user_id,
        exp: expires,
        iss: "Reckoning.io"
      }.compact

      self.token = JsonWebToken.encode(payload)
      break
    end
  end
end
