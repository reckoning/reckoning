# encoding: utf-8
# frozen_string_literal: true
module Backend
  module Api
    module V1
      class AccountsController < Backend::Api::BaseController
        respond_to :json

        def index
          authorize! :index, Account
          render json: Account.all, each_serializer: AccountSerializer
        end

        def show
          authorize! :show, account
          render json: account
        end

        def create
          authorize! :create, Account
          @account = Account.new(account_params)
          if @account.save
            render json: @account, status: :created
          else
            render json: ValidationError.new("account.create", @account.errors), status: :bad_request
          end
        end

        def update
          authorize! :update, account
          if account.update(account_params)
            render json: account, status: :ok
          else
            render json: ValidationError.new("account.update", account.errors), status: :bad_request
          end
        end

        def destroy
          authorize! :destroy, account
          if account.destroy
            render json: account, status: :ok
          else
            render json: ValidationError.new("account.destroy", account.errors), status: :bad_request
          end
        end

        private

        def account
          @account ||= Account.find(params.fetch(:id))
        end

        def account_params
          params.require(:account).permit(:name, :subdomain)
        end
      end
    end
  end
end
