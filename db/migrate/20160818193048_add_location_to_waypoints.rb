class AddPlaceToWaypoints < ActiveRecord::Migration[5.0]
  def change
    add_column :waypoints, :location, :string
  end
end
