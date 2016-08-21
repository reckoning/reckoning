class CreateWaypoints < ActiveRecord::Migration[5.0]
  def change
    create_table :waypoints, id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
      t.uuid :tour_id, null: false
      t.uuid :driver_id, null: false
      t.decimal :milage, precision: 10, scale: 2, default: 0.0, null: false
      t.float :latitude
      t.float :longitude
      t.datetime :time, null: false
      t.text :description

      t.timestamps
    end
  end
end
