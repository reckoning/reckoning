class AddTrailFieldsToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :trail_end_at, :datetime
    add_column :accounts, :trail_used, :boolean
  end
end
