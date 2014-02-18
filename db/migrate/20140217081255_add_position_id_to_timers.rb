class AddPositionIdToTimers < ActiveRecord::Migration
  def change
    add_column :timers, :position_id, :integer

    add_index "timers", ["position_id"], name: "index_timers_on_position_id", using: :btree
  end
end
