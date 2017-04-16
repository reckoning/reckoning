# encoding: utf-8
# frozen_string_literal: true
# taken from https://github.com/turn-project/turn/issues/33
module SessionHelper
  def add_authorization(user)
    @request.env['HTTP_AUTHORIZATION'] = http_authorization(user)
  end

  def http_authorization(user)
    token = AuthToken.find_or_create_by(user_id: user.id)
    ActionController::HttpAuthentication::Token.encode_credentials(token.token)
  end
end
