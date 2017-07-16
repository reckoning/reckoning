class AddAfaTypeToExpenses < ActiveRecord::Migration[5.1]
  def change
    add_column :expenses, :afa_type, :string
  end
end
