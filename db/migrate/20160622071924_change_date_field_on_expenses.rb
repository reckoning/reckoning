class ChangeDateFieldOnExpenses < ActiveRecord::Migration
  def change
    change_column :expenses, :date, :date
  end
end
