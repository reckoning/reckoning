class RemoveWeek < ActiveRecord::Migration
  def up
    drop_table :tasks_weeks
    remove_column :timers, :week_id, :uuid
    drop_table :weeks
  end

  def down
    create_table "weeks", id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.date "start_date"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.uuid "account_id", null: false
    end

    add_column :timers, :week_id, :uuid

    create_table "tasks_weeks", id: false, force: true do |t|
      t.uuid "week_id"
      t.uuid "task_id"
    end

    add_index "tasks_weeks", %w(task_id week_id), name: "index_tasks_weeks_on_task_id_and_week_id", using: :btree
    add_index "tasks_weeks", ["week_id"], name: "index_tasks_weeks_on_week_id", using: :btree
  end
end
