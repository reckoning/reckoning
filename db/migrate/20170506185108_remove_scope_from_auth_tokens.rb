class RemoveScopeFromAuthTokens < ActiveRecord::Migration[5.0]
  def change
    remove_column :auth_tokens, :scope, :string
    AuthToken.delete_all
  end
end
