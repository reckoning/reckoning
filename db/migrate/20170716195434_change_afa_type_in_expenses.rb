class ChangeAfaTypeInExpenses < ActiveRecord::Migration[5.1]
  def up
    change_column :expenses, :afa_type, 'integer USING CAST(afa_type AS integer)'
  end

  def down
    change_column :expenses, :afa_type, :string
  end
end
