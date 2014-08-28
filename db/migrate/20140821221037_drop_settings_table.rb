class DropSettingsTable < ActiveRecord::Migration
  def up
    drop_table :settings
  end

  def down
    create_table :settings do |t|
      t.string :keypath
      t.string :value

      t.timestamps
    end
  end
end
