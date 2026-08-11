# frozen_string_literal: true

module Api
  module V1
    module Backend
      # Admin-only. The web /backend namespace gates on `current_user.admin?`
      # and redirects; an API answers 403 instead.
      class BaseController < ::Api::BaseController
        skip_authorization_check

        before_action :verify_admin

        private def verify_admin
          return if current_user&.admin?

          render json: {
            code: "forbidden",
            message: I18n.t("validation_error.backend.admin_only")
          }, status: :forbidden
        end
      end
    end
  end
end
