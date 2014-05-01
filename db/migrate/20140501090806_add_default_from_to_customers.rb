class AddDefaultFromToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :default_from, :string
  end
end
