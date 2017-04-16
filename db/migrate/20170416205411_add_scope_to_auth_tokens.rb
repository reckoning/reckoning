class AddScopeToAuthTokens < ActiveRecord::Migration[5.0]
  def change
    add_column :auth_tokens, :scope, :string, default: :system
  end
end
