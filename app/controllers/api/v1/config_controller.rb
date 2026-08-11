# frozen_string_literal: true

module Api
  module V1
    # What the SPA has to know before anyone signs in: whether to offer signup,
    # and which account the subdomain resolves to. The server-rendered login
    # reads both straight from the request; the SPA has to ask.
    class ConfigController < ::Api::BaseController
      skip_authorization_check
      skip_before_action :authenticate_user!

      def show
      end
    end
  end
end
