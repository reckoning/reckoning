class CreateTours < ActiveRecord::Migration[5.0]
  def change
    create_table :tours, id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
      t.uuid :account_id, null: false
      t.text :description
      t.uuid :vessel_id, null: false

      t.timestamps
    end
  end
end
