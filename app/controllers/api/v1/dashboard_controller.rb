# frozen_string_literal: true

module Api
  module V1
    # Totals for the SPA home screen. Mirrors what BaseController#dashboard
    # assembles for the server-rendered dashboard.
    class DashboardController < ::Api::BaseController
      skip_authorization_check

      def show
        @year = Time.zone.now.year
        @uninvoiced_amount = current_account.uninvoiced_amount
        @charged_sum = current_account.invoices.charged.sum(:value)
        @paid_sum = current_account.invoices.paid_in_year(@year).sum(:value)
        @last_year_paid_sum = current_account.invoices.paid_in_year(@year - 1).sum(:value)
        @expenses_sum = expenses_sum_for(@year)
        @last_year_expenses_sum = expenses_sum_for(@year - 1)
        @open_invoices_count = current_account.invoices.created.count
        @provision = current_account.provision_value
        @last_year_provision = current_account.last_provision_value
        @overtime = overtime
        # The chart covers this year and the last, and the series are sums per
        # month over both — deriving them in the client would mean shipping
        # two years of invoices to add them up there.
        @chart = Charts::InvoicesService.new(chart_scope).data
      end

      # `Customer#overtime` is the tracked time against what was scheduled, and
      # it only answers for an employed customer with workdays and weekly
      # hours. The panel skips the rest.
      private def overtime
        customers = current_account.customers.filter_map do |customer|
          hours = customer.overtime(current_user.id)
          next if hours.nil? || customer.weekly_hours.blank?

          {name: customer.name, hours: hours, weekly_hours: customer.weekly_hours}
        end

        {
          weekly_hours: current_user.weekly_hours,
          daily_hours: current_user.daily_hours,
          customers: customers
        }
      end

      private def chart_scope
        current_account.invoices.paid_or_charged
          .where(date: 1.year.ago.beginning_of_year..Time.zone.now.end_of_year)
      end

      private def expenses_sum_for(year)
        normalized = ::Expense.normalized(
          current_account.expenses.without_insurances.year(year).to_a,
          year: year
        )

        normalized.sum { |expense| expense.usable_value(year) }
      end
    end
  end
end
