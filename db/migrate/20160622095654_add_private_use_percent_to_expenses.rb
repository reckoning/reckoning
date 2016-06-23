class AddPrivateUsePercentToExpenses < ActiveRecord::Migration
  def change
    add_column :expenses, :private_use_percent, :integer, default: 0, null: false
  end
end
