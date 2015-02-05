class AddAccountIdToInvoicesCustomersAndWeeks < ActiveRecord::Migration
  def change
    add_column :invoices, :account_id, :uuid
    add_column :weeks, :account_id, :uuid
    add_column :customers, :account_id, :uuid
  end
end
