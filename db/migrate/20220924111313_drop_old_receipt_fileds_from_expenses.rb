class DropOldReceiptFiledsFromExpenses < ActiveRecord::Migration[6.1]
  def change
    remove_column :expenses, :receipt, :string
    remove_column :expenses, :receipt_id, :string
    remove_column :expenses, :receipt_filename, :string
    remove_column :expenses, :receipt_size, :integer
    remove_column :expenses, :receipt_content_type, :string
  end
end
