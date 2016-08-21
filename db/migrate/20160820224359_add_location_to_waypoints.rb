class AddLocationToWaypoints < ActiveRecord::Migration[5.0]
  def change
    add_column :waypoints, :location, :string, null: false
  end
end
