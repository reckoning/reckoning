class AddNotNullConstraintsToAccountIdFields < ActiveRecord::Migration
  def change
    change_column :users, :account_id, :uuid, null: false
    change_column :invoices, :account_id, :uuid, null: false
    change_column :customers, :account_id, :uuid, null: false
    change_column :weeks, :account_id, :uuid, null: false
  end
end
