class RenameValueInTimers < ActiveRecord::Migration
  def change
    remove_column :timers, :value, :string
    rename_column :timers, :value_dec, :value
  end
end
