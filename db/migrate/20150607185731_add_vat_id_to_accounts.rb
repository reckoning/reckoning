class AddVatIdToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :vat_id, :string
  end
end
