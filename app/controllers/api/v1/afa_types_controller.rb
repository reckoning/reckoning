# frozen_string_literal: true

module Api
  module V1
    # The depreciation classes the expense form offers once its type is AfA.
    # A reference table rather than the account's own data, so there is
    # nothing to scope — but it is only of use with expenses switched on.
    class AfaTypesController < ::Api::BaseController
      before_action :check_feature_enabled

      def index
        authorize! :read, :expenses

        @afa_types = ::AfaType.i18n.order(name: :asc)
      end

      private def check_feature_enabled
        return if current_account.feature_expenses?

        render json: {
          code: "feature.disabled",
          message: I18n.t("validation_error.expense.feature_disabled")
        }, status: :forbidden
      end
    end
  end
end
