class DropAuthTokens < ActiveRecord::Migration[6.1]
  def up
    drop_table :auth_tokens
  end

  def down
    create_table "auth_tokens", id: :uuid, default: -> { "uuid_generate_v4()" }, force: :cascade do |t|
      t.uuid "user_id", null: false
      t.string "token"
      t.text "description"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.string "user_agent"
      t.integer "expires"
      t.index ["token", "user_id"], name: "index_auth_tokens_on_token_and_user_id", unique: true
      t.index ["token"], name: "index_auth_tokens_on_token"
    end
  end
end
