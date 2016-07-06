class RemoveStartedFromTimers < ActiveRecord::Migration
  def change
    remove_column :timers, :started, :boolean, default: false
  end
end
