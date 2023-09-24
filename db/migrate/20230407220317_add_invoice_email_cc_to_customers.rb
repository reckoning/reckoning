class AddInvoiceEmailCcToCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :invoice_email_cc, :string
  end
end
