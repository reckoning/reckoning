# frozen_string_literal: true

module Api
  module V1
    module Backend
      class UsersController < BaseController
        rescue_from ActiveRecord::RecordNotFound do |_exception|
          not_found(I18n.t("messages.record_not_found.base"))
        end

        after_action -> { pagination_header(:users) }, only: [:index]

        def index
          @users = paginate(::User.all.order(created_at: :desc))
        end

        def show
          @user = ::User.find(params[:id])
        end

        # Mirrors the web flow: the admin never sets a password, the user gets
        # a confirmation mail and picks their own.
        def create
          password = Devise.friendly_token.first(30)
          @user = ::User.new(user_params.merge(password: password, password_confirmation: password))
          @user.skip_confirmation_notification!

          if @user.save
            render :show, status: :created
          else
            render json: ValidationError.new("user.create", @user.errors), status: :bad_request
          end
        end

        def update
          @user = ::User.find(params[:id])

          return render :show if @user.update(user_params)

          render json: ValidationError.new("user.update", @user.errors), status: :bad_request
        end

        def destroy
          @user = ::User.find(params[:id])

          if @user.destroy
            render json: {message: resource_message(:user, :destroy, :success)}
          else
            render json: ValidationError.new("user.destroy", @user.errors), status: :bad_request
          end
        end

        def send_welcome
          @user = ::User.find(params[:id])

          if @user.send_confirmation_instructions
            render json: {message: I18n.t(:"messages.user.send_welcome.success")}
          else
            render json: ValidationError.new("user.send_welcome", @user.errors), status: :bad_request
          end
        end

        private def user_params
          openapi_params(::V1::Schemas::Inputs::BackendUserInput)
        end
      end
    end
  end
end
