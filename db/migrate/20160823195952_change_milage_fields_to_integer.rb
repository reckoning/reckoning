class ChangeMilageFieldsToInteger < ActiveRecord::Migration[5.0]
  def up
    change_column :vessels, :milage, :integer
    change_column :vessels, :initial_milage, :integer
    change_column :waypoints, :milage, :integer
  end

  def down
    change_column :waypoints, :milage, :decimal, precision: 10, scale: 2
    change_column :vessels, :milage, :decimal, precision: 10, scale: 2
    change_column :vessels, :initial_milage, :decimal, precision: 10, scale: 2
  end
end
