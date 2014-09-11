class ConvertUserIdAndCustomerIdToUuids < ActiveRecord::Migration
  def up
    enable_extension "uuid-ossp"

    # address start
    add_column :addresses, :uuid_resource_id, :uuid

    # users
    add_column :users, :uuid, :uuid, default: 'uuid_generate_v4()'
    add_column :customers, :uuid_user_id, :uuid
    add_column :weeks, :uuid_user_id, :uuid
    add_column :invoices, :uuid_user_id, :uuid
    User.all.each do |user|
      Customer.where(user_id: user.id).update_all(uuid_user_id: user.uuid)
      Week.where(user_id: user.id).update_all(uuid_user_id: user.uuid)
      Invoice.where(user_id: user.id).update_all(uuid_user_id: user.uuid)
      Address.where(resource_id: user.id, resource_type: "User").update_all(uuid_resource_id: user.uuid)
    end
    remove_column :customers, :user_id
    remove_column :weeks, :user_id
    remove_column :invoices, :user_id
    rename_column :customers, :uuid_user_id, :user_id
    rename_column :weeks, :uuid_user_id, :user_id
    rename_column :invoices, :uuid_user_id, :user_id
    remove_column :users, :id
    rename_column :users, :uuid, :id
    execute "ALTER TABLE users ADD PRIMARY KEY (id);"

    # customers
    add_column :customers, :uuid, :uuid, default: 'uuid_generate_v4()'
    add_column :invoices, :uuid_customer_id, :uuid
    add_column :projects, :uuid_customer_id, :uuid
    Customer.all.each do |customer|
      Project.where(customer_id: customer.id).update_all(uuid_customer_id: customer.uuid)
      Invoice.where(customer_id: customer.id).update_all(uuid_customer_id: customer.uuid)
      Address.where(resource_id: customer.id, resource_type: "Customer").update_all(uuid_resource_id: customer.uuid)
    end
    remove_column :invoices, :customer_id
    remove_column :projects, :customer_id
    rename_column :invoices, :uuid_customer_id, :customer_id
    rename_column :projects, :uuid_customer_id, :customer_id
    remove_column :customers, :id
    rename_column :customers, :uuid, :id
    execute "ALTER TABLE customers ADD PRIMARY KEY (id);"

    # address end
    remove_column :addresses, :resource_id
    rename_column :addresses, :uuid_resource_id, :resource_id

    # projects
    add_column :projects, :uuid, :uuid, default: 'uuid_generate_v4()'
    add_column :invoices, :uuid_project_id, :uuid
    add_column :tasks, :uuid_project_id, :uuid
    Project.all.each do |project|
      Invoice.where(project_id: project.id).update_all(uuid_project_id: project.uuid)
      Task.where(project_id: project.id).update_all(uuid_project_id: project.uuid)
    end
    remove_column :invoices, :project_id
    rename_column :invoices, :uuid_project_id, :project_id
    remove_column :tasks, :project_id
    rename_column :tasks, :uuid_project_id, :project_id
    remove_column :projects, :id
    rename_column :projects, :uuid, :id
    execute "ALTER TABLE projects ADD PRIMARY KEY (id);"

    # invoices
    add_column :invoices, :uuid, :uuid, default: 'uuid_generate_v4()'
    add_column :positions, :uuid_invoice_id, :uuid
    Invoice.all.each do |invoice|
      Position.where(invoice_id: invoice.id).update_all(uuid_invoice_id: invoice.uuid)
    end
    remove_column :positions, :invoice_id
    rename_column :positions, :uuid_invoice_id, :invoice_id
    remove_column :invoices, :id
    rename_column :invoices, :uuid, :id
    execute "ALTER TABLE invoices ADD PRIMARY KEY (id);"

    # positions
    add_column :positions, :uuid, :uuid, default: 'uuid_generate_v4()'
    add_column :timers, :uuid_position_id, :uuid
    Position.all.each do |position|
      Timer.where(position_id: position.id).update_all(uuid_position_id: position.uuid)
    end
    remove_column :timers, :position_id
    rename_column :timers, :uuid_position_id, :position_id
    remove_column :positions, :id
    rename_column :positions, :uuid, :id
    execute "ALTER TABLE positions ADD PRIMARY KEY (id);"

    # tasks
    add_column :tasks, :uuid, :uuid, default: 'uuid_generate_v4()'
    add_column :timers, :uuid_task_id, :uuid
    Task.all.each do |task|
      Timer.where(task_id: task.id).update_all(uuid_task_id: task.uuid)
    end
    remove_column :timers, :task_id
    rename_column :timers, :uuid_task_id, :task_id

    # weeks
    add_column :weeks, :uuid, :uuid, default: 'uuid_generate_v4()'
    add_column :timers, :uuid_week_id, :uuid
    Week.all.each do |week|
      Timer.where(week_id: week.id).update_all(uuid_week_id: week.uuid)
    end
    remove_column :timers, :week_id
    rename_column :timers, :uuid_week_id, :week_id

    add_column :tasks_weeks, :uuid_week_id, :uuid
    execute %{
      UPDATE tasks_weeks SET uuid_week_id = weeks.uuid
      FROM weeks
      WHERE week_id = weeks.id
    }
    remove_column :tasks_weeks, :week_id
    rename_column :tasks_weeks, :uuid_week_id, :week_id

    add_column :tasks_weeks, :uuid_task_id, :uuid
    execute %{
      UPDATE tasks_weeks SET uuid_task_id = tasks.uuid
      FROM tasks
      WHERE task_id = tasks.id
    }
    remove_column :tasks_weeks, :task_id
    rename_column :tasks_weeks, :uuid_task_id, :task_id
    add_index :tasks_weeks, [:task_id, :week_id]
    add_index :tasks_weeks, :week_id

    remove_column :tasks, :id
    rename_column :tasks, :uuid, :id
    execute "ALTER TABLE tasks ADD PRIMARY KEY (id);"
    remove_column :weeks, :id
    rename_column :weeks, :uuid, :id
    execute "ALTER TABLE weeks ADD PRIMARY KEY (id);"

    add_column :timers, :uuid, :uuid, default: 'uuid_generate_v4()'
    remove_column :timers, :id
    rename_column :timers, :uuid, :id
    execute "ALTER TABLE timers ADD PRIMARY KEY (id);"

    add_column :timers, :uuid, :uuid, default: 'uuid_generate_v4()'
    remove_column :timers, :id
    rename_column :timers, :uuid, :id
    execute "ALTER TABLE timers ADD PRIMARY KEY (id);"
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Wont go back to plain ids"
  end
end
