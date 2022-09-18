class AddAfaTypeIdToExpenses < ActiveRecord::Migration[6.1]
  def change
    add_column :expenses, :afa_type_id, :uuid
    rename_column :expenses, :afa_type, :afa_type_old
  end
end
