class RemoveUserIdsAndHstoreFieldsFromUsers < ActiveRecord::Migration
  def change
    remove_column :invoices, :user_id
    remove_column :weeks, :user_id
    remove_column :customers, :user_id
    remove_column :users, :settings
    remove_column :users, :bank_account
    remove_column :users, :services
    remove_column :users, :mailing
    remove_column :users, :contact_information
  end
end
