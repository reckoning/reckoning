# frozen_string_literal: true

module AccountsConcern
  extend ActiveSupport::Concern

  included do
    helper_method :current_account
  end

  def current_account
    @current_account ||= if current_user.present?
                           current_user.account
                         elsif request.subdomain.present? && request.subdomain != 'www' && request.subdomain != 'api'
                           Account.where(subdomain: request.subdomain).first
                         end
  end
end
