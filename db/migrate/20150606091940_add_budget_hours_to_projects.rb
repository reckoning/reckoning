class AddBudgetHoursToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :budget_hours, :decimal, precision: 10, scale: 2, default: 0.0, null: false

    Project.all.each do |project|
      project.budget_hours = project.budget
      project.save
    end
  end
end
