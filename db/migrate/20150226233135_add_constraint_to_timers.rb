class AddConstraintToTimers < ActiveRecord::Migration
  def change
    change_column :timers, :user_id, :uuid, null: false
  end
end
