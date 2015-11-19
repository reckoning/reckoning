class AddLayoutToUsers < ActiveRecord::Migration
  def change
    add_column :users, :layout, :string, default: :top
  end
end
