class DropContacts < ActiveRecord::Migration[6.1]
  def up
    drop_table :contacts
  end

  def down
    create_table "contacts", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.string "email"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.index ["email"], name: "index_contacts_on_email", unique: true
    end
  end
end
