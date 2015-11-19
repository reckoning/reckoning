class ChangeStateFieldsForWorkflowGemInInvoicesAndProjects < ActiveRecord::Migration
  def change
    rename_column :invoices, :state, :workflow_state
    rename_column :projects, :state, :workflow_state
  end
end
