class AddMissingIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :auth_tokens, [:token, :user_id], unique: true
    add_index :invoices, [:ref, :account_id], unique: true
    add_index :contacts, :email, unique: true
  end
end
