class AddInvoiceEmailToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :invoice_email, :string
  end
end
