class ChangeNullableForDateOnExpenses < ActiveRecord::Migration[6.1]
  def up
    change_column :expenses, :date, :date, null: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
