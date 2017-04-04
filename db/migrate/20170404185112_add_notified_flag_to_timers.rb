class AddNotifiedFlagToTimers < ActiveRecord::Migration[5.0]
  def change
    add_column :timers, :notified, :boolean, default: false
  end
end
