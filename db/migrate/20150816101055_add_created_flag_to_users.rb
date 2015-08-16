class AddCreatedFlagToUsers < ActiveRecord::Migration
  def change
    add_column :users, :created_via_admin, :boolean, default: false
  end
end
