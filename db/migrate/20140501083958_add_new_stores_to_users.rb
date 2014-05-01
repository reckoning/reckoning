class AddNewStoresToUsers < ActiveRecord::Migration
  def change
    add_column :users, :services, :hstore
    add_column :users, :mailing, :hstore
  end
end
