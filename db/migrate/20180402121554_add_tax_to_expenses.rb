class AddTaxToExpenses < ActiveRecord::Migration[5.1]
  def change
    add_column :expenses, :vat_percent, :integer, default: 0, null: false
  end
end
