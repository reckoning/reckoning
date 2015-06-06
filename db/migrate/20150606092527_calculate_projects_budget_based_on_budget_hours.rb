class CalculateProjectsBudgetBasedOnBudgetHours < ActiveRecord::Migration
  def change
    Project.all.each do |project|
      next if project.rate.blank?
      project.budget = project.rate * project.budget_hours
      project.save
    end
  end
end
