# encoding: utf-8
# frozen_string_literal: true

module Api
  module V1
    class UsersController < ::Api::BaseController
      def index
        authorize! :index, User
        @users = User.where(account_id: current_account.id)
      end

      def current
        authorize! :read, User
        @user = current_user
      end
    end
  end
end
