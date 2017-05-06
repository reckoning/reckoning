# encoding: utf-8
# frozen_string_literal: true

module Concerns
  module Accounts
    extend ActiveSupport::Concern

    included do
      helper_method :current_account
    end

    def current_account
      @current_account ||= begin
        if current_user.present?
          current_user.account
        elsif request.subdomain.present? && request.subdomain != "www" && request.subdomain != "api"
          Account.where(subdomain: request.subdomain).first
        end
      end
    end
  end
end
