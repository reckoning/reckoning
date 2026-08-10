# frozen_string_literal: true

module Api
  module V1
    # Totals for the SPA home screen. Mirrors what BaseController#dashboard
    # assembles for the server-rendered dashboard, minus the chart series,
    # which the client can derive from the invoice list.
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
