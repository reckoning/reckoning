# frozen_string_literal: true

module Api
  module V1
    module Backend
      # What the backend dashboard shows next to its list of the latest
      # users: how many there are in total, across every account.
      class StatsController < BaseController
        def show
          @users_count = ::User.count
          @accounts_count = ::Account.count
        end
      end
    end
  end
end
