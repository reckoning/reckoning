class AddRecurringExpensesFieldsToExpenses < ActiveRecord::Migration[6.1]
  def change
    add_column :expenses, :started_at, :date
    add_column :expenses, :ended_at, :date
    add_column :expenses, :interval, :integer, default: 0, null: false
  end
end
