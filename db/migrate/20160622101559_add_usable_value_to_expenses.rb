class AddUsableValueToExpenses < ActiveRecord::Migration
  def change
    add_column :expenses, :usable_value, :decimal, precision: 10, scale: 2, default: 0.0, null: false
  end
end
