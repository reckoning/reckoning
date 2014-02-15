class AddBudgetToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :budget, :decimal, precision: 10, scale: 2, default: 0.0,   null: false
  end
end
