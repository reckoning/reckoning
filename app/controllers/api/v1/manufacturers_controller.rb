# encoding: utf-8
# frozen_string_literal: true
module Api
  module V1
    class ManufacturersController < ::Api::BaseController
      def index
        authorize! :index, :manufacturer
        @manufacturers = Vessel.where(account_id: current_account.id).map(&:manufacturer)
      end
    end
  end
end
