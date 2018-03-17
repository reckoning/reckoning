class DropUseableValueFromExpenses < ActiveRecord::Migration[5.1]
  def change
    remove_column :expenses, :usable_value, :decimal, precision: 10, scale: 2, default: "0.0", null: false
  end
end
