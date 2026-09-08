# frozen_string_literal: true

json.year @year
json.uninvoiced_amount @uninvoiced_amount
json.charged_sum @charged_sum
json.paid_sum @paid_sum
json.last_year_paid_sum @last_year_paid_sum
json.expenses_sum @expenses_sum
json.last_year_expenses_sum @last_year_expenses_sum
json.open_invoices_count @open_invoices_count

# Only with a provision rate on the account — otherwise both are nil and the
# panel leaves the rows out, the way the server-rendered one does.
json.provision @provision
json.last_year_provision @last_year_provision

json.overtime do
  json.weekly_hours @overtime[:weekly_hours]
  json.daily_hours @overtime[:daily_hours]
  json.customers @overtime[:customers] do |customer|
    json.name customer[:name]
    json.hours customer[:hours]
    json.weekly_hours customer[:weekly_hours]
  end
end

# This year and the last, each as a running total and as sums per month.
json.chart do
  json.labels @chart[:labels]
  json.datasets @chart[:datasets] do |dataset|
    json.name dataset[:name]
    json.color dataset[:color]
    json.data dataset[:data]
  end
end
