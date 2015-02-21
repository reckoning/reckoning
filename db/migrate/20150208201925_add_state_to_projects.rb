class AddStateToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :state, :string, null: false, default: :active
  end
end
