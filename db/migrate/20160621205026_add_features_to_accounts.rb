class AddFeaturesToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :feature_expenses, :boolean, default: false
  end
end
