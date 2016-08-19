class CreateVessels < ActiveRecord::Migration[5.0]
  def change
    create_table :vessels, id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
      t.string :manufacturer, null: false
      t.string :vessel_type, null: false
      t.decimal :buying_price, precision: 10, scale: 2, default: 0.0, null: false
      t.date :buying_date
      t.decimal :initial_milage, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :milage, precision: 10, scale: 2, default: 0.0, null: false
      t.string :image_id
      t.string :license_plate, null: false
      t.uuid :account_id, null: false

      t.timestamps
    end
  end
end
