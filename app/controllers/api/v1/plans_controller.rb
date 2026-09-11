# frozen_string_literal: true

module Api
  module V1
    # The welcome page's pricing table. Open, like the page: a visitor has no
    # session yet, and the prices are what they came to read.
    class PlansController < ::Api::BaseController
      skip_authorization_check
      skip_before_action :authenticate_user!

      def index
        @plans = ::Plan.all.sort_by { |plan| plan.price.cents }
      end
    end
  end
end
