class RemoveStartedFromTimers < ActiveRecord::Migration
  def up
    remove_column :timers, :started, :boolean

    Timer.where.not(started_at: nil).update_all(started_at: nil)
  end

  def down
    add_column :timers, :started, :boolean, default: false
  end
end
