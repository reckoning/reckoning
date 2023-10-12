class ChangeDateFieldsOnProjects < ActiveRecord::Migration[6.1]
  def up
    change_column :projects, :start_date, :date, null: true
    change_column :projects, :end_date, :date, null: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
