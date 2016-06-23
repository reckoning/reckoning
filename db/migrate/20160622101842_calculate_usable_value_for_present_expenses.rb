class CalculateUsableValueForPresentExpenses < ActiveRecord::Migration
  def up
    Expense.find_each do |expense|
      expense.usable_value = (expense.value * (100 - expense.private_use_percent).to_f) / 100.0
      expense.save
    end
  end

  def down
  end
end
