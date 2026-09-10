# frozen_string_literal: true

module Api
  module V1
    module Backend
      class AccountsController < BaseController
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        after_action -> { pagination_header(:accounts) }, only: [:index]

        def index
          @accounts = paginate(::Account.includes(:users).order(created_at: :desc))
        end

        def show
          @account = ::Account.find(params[:id])
        end

        # Mirrors the web flow: an account cannot exist without a user, so the
        # first one comes with it and is mailed a confirmation to pick their
        # own password.
        def create
          attributes = account_params
          @account = ::Account.new(attributes.except(:email).reverse_merge(plan: "free"))
          @account.users.build(email: attributes[:email], created_via_admin: true, password: generated_password)

          if @account.save
            render :show, status: :created
          else
            render json: ValidationError.new("account.create", @account.errors), status: :bad_request
          end
        end

        def update
          @account = ::Account.find(params[:id])

          return render :show if @account.update(account_params.except(:email))

          render json: ValidationError.new("account.update", @account.errors), status: :bad_request
        end

        def destroy
          @account = ::Account.find(params[:id])

          if @account.destroy
            render json: {message: resource_message(:account, :destroy, :success)}
          else
            render json: ValidationError.new("account.destroy", @account.errors), status: :bad_request
          end
        end

        private def generated_password
          @generated_password ||= Devise.friendly_token.first(16)
        end

        private def account_params
          openapi_params(::V1::Schemas::Inputs::BackendAccountInput)
        end
      end
    end
  end
end
