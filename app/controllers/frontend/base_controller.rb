# frozen_string_literal: true

module Frontend
  class BaseController < ApplicationController
    layout "frontend"

    def index
      route = request.fullpath.split("?").first.sub(%r{^/}, "").tr("/", "_")
      route = "home" if route.blank?

      @title = I18n.t("title.frontend.#{route}")

      render_frontend
    end

    def not_found
      respond_to do |format|
        format.html do
          render "frontend/index", status: :not_found
        end
        format.json do
          render json: {code: "not_found", message: "Not Found"}, status: :not_found
        end
        format.all do
          redirect_to "/404"
        end
      end
    end

    private def render_frontend
      respond_to do |format|
        format.html do
          render "frontend/index", status: :ok
        end
        format.all do
          redirect_to "/404"
        end
      end
    end
  end
end
