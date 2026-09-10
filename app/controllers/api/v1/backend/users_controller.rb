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
          @users = paginate(::User.all.order(*order_clause))
        end

        def show
          @user = ::User.find(params[:id])
        end

        # The admin never sets a password: a random one goes in and the user is
        # mailed a confirmation to pick their own. `created_via_admin` is what
        # makes that mail say where the account came from.
        #
        # The notification used to be suppressed here, which left a created
        # user with no way in at all until an admin remembered to press the
        # button on the list — the list's button is for sending it *again*.
        def create
          password = Devise.friendly_token.first(30)
          @user = ::User.new(user_params.merge(password: password, password_confirmation: password))
          @user.created_via_admin = true

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

        # The columns the server-rendered list let you sort by. Written as
        # order hashes rather than SQL, so the parameter cannot reach the
        # ORDER BY even in principle. `id` closes every order: emails and
        # timestamps repeat, and offset paging over a tie can show a row
        # twice or skip it.
        private def order_clause
          direction = (params[:direction] == "asc") ? :asc : :desc

          case params[:sort]
          when "id" then [{id: direction}]
          when "email" then [{email: direction}, {id: :desc}]
          when "admin" then [{admin: direction}, {id: :desc}]
          when "current_sign_in_at" then [{current_sign_in_at: direction}, {id: :desc}]
          else [{created_at: direction}, {id: :desc}]
          end
        end

        private def user_params
          openapi_params(::V1::Schemas::Inputs::BackendUserInput)
        end
      end
    end
  end
end
