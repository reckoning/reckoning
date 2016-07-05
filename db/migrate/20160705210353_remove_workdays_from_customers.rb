class RemoveWorkdaysFromCustomers < ActiveRecord::Migration
  def change
    remove_column :customers, :workdays, :integer
  end
end
