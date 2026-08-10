# frozen_string_literal: true

module Api
  module V1
    class UsersController < ::Api::BaseController
      # `:manage` rather than `:index` / `:read`: those are class-level checks,
      # which CanCan satisfies from any conditional rule on User — including
      # "can read your own record", which every user now has for /me. Only
      # admins have `can :manage, User`.
      def index
        authorize! :manage, User
        @users = User.where(account_id: current_account.id)
      end

      def current
        authorize! :manage, User
        @user = current_user
      end
    end
  end
end
