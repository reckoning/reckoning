class AddFederalStateToProjects < ActiveRecord::Migration[6.1]
  def change
    add_column :projects, :federal_state, :string
  end
end
