class AddNoteToTimers < ActiveRecord::Migration
  def change
    add_column :timers, :note, :text
  end
end
