class AddFeatureLogbookToggleToAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :feature_logbook, :boolean, default: false
  end
end
