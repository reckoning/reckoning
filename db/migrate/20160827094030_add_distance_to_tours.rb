class AddDistanceToTours < ActiveRecord::Migration[5.0]
  def change
    add_column :tours, :distance, :integer, default: 0, null: false
    add_column :tours, :duration, :integer, default: 0, null: false
  end
end
