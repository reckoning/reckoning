# encoding: utf-8
# frozen_string_literal: true
class JsonWebToken
  class << self
    def encode(payload)
      JWT.encode(payload, Rails.application.secrets[:devise_jwt])
    end

    def decode(token)
      body = JWT.decode(token, Rails.application.secrets[:devise_jwt])[0]
      HashWithIndifferentAccess.new body
      # rubocop:disable Lint/RescueException
    rescue Exception => e
      Rails.logger.debug(e)
      nil
    end
  end
end
