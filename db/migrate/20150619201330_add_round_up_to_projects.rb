class AddRoundUpToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :round_up, :decimal, default: 10.0, null: false
  end
end
