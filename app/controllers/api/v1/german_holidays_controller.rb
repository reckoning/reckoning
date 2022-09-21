# frozen_string_literal: true

module Api
  module V1
    class GermanHolidaysController < Api::BaseController
      def index
        authorize! :index, GermanHoliday

        scope = GermanHoliday

        Rails.logger.debug(params)
        scope = scope.where(federal_state: params[:state]) if params[:state].present?

        scope = scope.where("extract(year from date) = ?", params[:year]) if params[:year].present?

        @german_holidays = scope.order(date: :desc, federal_state: :asc).all
      end
    end
  end
end
