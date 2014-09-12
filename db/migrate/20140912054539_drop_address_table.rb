class DropAddressTable < ActiveRecord::Migration
  def up
    drop_table :addresses
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Wont go back to plain ids"
  end
end
