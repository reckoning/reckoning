class AddInvoiceEmailBccToCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :invoice_email_bcc, :string
  end
end
