class AddBudgetOnDashboardToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :budget_on_dashboard, :boolean, default: true
  end
end
