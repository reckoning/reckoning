class AddValueDecToTimers < ActiveRecord::Migration
  def change
    add_column :timers, :value_dec, :decimal, precision: 30, scale: 18
  end
end
