class AddIndexToAuthTokens < ActiveRecord::Migration[5.0]
  def change
    add_index :auth_tokens, :token
  end
end
