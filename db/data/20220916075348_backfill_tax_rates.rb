# frozen_string_literal: true

class BackfillTaxRates < ActiveRecord::Migration[6.1]
  def up
    Account.find_each do |account|
      TaxRate.find_or_create_by(account_id: account.id, value: account.tax) do |tax_rate|
        tax_rate.valid_from = Date.new(1970, 1, 1)
      end
    end
  end

  def down
  end
end
