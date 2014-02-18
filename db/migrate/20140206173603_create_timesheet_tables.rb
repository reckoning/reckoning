class CreateTimesheetTables < ActiveRecord::Migration
  def up
    create_table :weeks do |t|
      t.date :start_date
      t.references :user, index: true

      t.timestamps
    end

    create_table :tasks do |t|
      t.references :project, index: true
      t.string :name

      t.timestamps
    end

    create_table :timers do |t|
      t.date :date
      t.string :value
      t.references :task, index: true
      t.references :week, index: true

      t.timestamps
    end

    create_table :tasks_weeks, :id => false do |t|
        t.references :task
        t.references :week
    end
    add_index :tasks_weeks, [:task_id, :week_id]
    add_index :tasks_weeks, :week_id
  end

  def down
    drop_table :tasks_weeks
    drop_table :timers
    drop_table :tasks
    drop_table :weeks
  end
end
