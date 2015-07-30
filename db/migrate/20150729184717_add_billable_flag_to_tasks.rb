class AddBillableFlagToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :billable, :boolean, default: true, null: false
  end
end
