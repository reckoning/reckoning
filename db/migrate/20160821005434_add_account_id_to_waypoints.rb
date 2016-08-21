class AddAccountIdToWaypoints < ActiveRecord::Migration[5.0]
  def change
    add_column :waypoints, :account_id, :uuid, null: false
  end
end
