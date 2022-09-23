class AddBusinessDaysToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :business_days, :integer
  end
end
