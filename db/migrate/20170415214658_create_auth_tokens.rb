class CreateAuthTokens < ActiveRecord::Migration[5.0]
  def change
    create_table :auth_tokens, id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
      t.uuid :user_id, null: false
      t.string :token
      t.text :description

      t.timestamps
    end
  end
end
