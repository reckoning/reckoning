# encoding: utf-8
# frozen_string_literal: true
class AuthToken < ApplicationRecord
  belongs_to :user

  validates :token, presence: true, uniqueness: { scope: :user_id }
  validates :user_id, presence: true

  before_validation :generate_authentication_token, on: :create

  private def generate_authentication_token
    loop do
      auth_token = Devise.friendly_token
      unless AuthToken.find_by(user_id: user_id, token: auth_token)
        self.token = auth_token
        break
      end
    end
  end
end
