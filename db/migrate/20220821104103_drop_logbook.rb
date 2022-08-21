class DropLogbook < ActiveRecord::Migration[6.1]
  def up
    drop_table :tours
    drop_table :vessels
    drop_table :waypoints
  end

  def down
    create_table "tours", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid "account_id", null: false
      t.text "description"
      t.uuid "vessel_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "distance", default: 0, null: false
      t.integer "duration", default: 0, null: false
    end

    create_table "vessels", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string "manufacturer", null: false
      t.string "vessel_type", null: false
      t.decimal "buying_price", precision: 10, scale: 2, default: "0.0"
      t.date "buying_date", null: false
      t.integer "initial_milage", default: 0, null: false
      t.integer "milage", default: 0, null: false
      t.string "image_id"
      t.string "license_plate", null: false
      t.uuid "account_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    create_table "waypoints", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid "tour_id", null: false
      t.uuid "driver_id", null: false
      t.integer "milage", default: 0, null: false
      t.float "latitude"
      t.float "longitude"
      t.datetime "time", null: false
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "location", null: false
      t.uuid "account_id", null: false
    end
  end
end
