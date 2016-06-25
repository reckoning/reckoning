class AddReceiptIdToExpenses < ActiveRecord::Migration
  def change
    add_column :expenses, :receipt_id, :string
    add_column :expenses, :receipt_filename, :string
    add_column :expenses, :receipt_size, :integer
    add_column :expenses, :receipt_content_type, :string
  end
end
