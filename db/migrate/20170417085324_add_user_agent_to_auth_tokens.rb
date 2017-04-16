class AddUserAgentToAuthTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :auth_tokens, :user_agent, :string
    add_column :auth_tokens, :expires, :int, default: nil
  end
end
