# frozen_string_literal: true

class RenameTrailToTrialOnAccounts < ActiveRecord::Migration[8.1]
  def change
    rename_column :accounts, :trail_end_at, :trial_end_at
    rename_column :accounts, :trail_used, :trial_used
  end
end
