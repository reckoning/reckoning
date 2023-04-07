class AddInvoiceAdditionToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :invoice_addition, :text
  end
end
