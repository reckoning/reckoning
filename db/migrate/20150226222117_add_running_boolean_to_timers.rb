class AddRunningBooleanToTimers < ActiveRecord::Migration
  def change
    add_column :timers, :started, :boolean, default: false
    add_column :timers, :started_at, :datetime
  end
end
