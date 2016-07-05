class AddWorkdaysToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :workdays, :integer, default: 0
    add_column :customers, :employment_date, :date
    add_column :customers, :weekly_hours, :integer
  end
end
