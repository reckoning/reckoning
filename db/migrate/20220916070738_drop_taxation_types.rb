class DropTaxationTypes < ActiveRecord::Migration[6.1]
  def up
    drop_table :taxation_types
  end

  def down
    create_table "taxation_types", force: :cascade do |t|
      t.uuid "account_id"
      t.decimal "tax"
      t.date "date"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end
  end
end
