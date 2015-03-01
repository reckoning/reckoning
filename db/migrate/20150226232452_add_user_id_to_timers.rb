class AddUserIdToTimers < ActiveRecord::Migration
  def change
    add_column :timers, :user_id, :uuid
  end
end
