# frozen_string_literal: true

class GrandfatherExistingTrials < ActiveRecord::Migration[8.1]
  def up
    # Every account predating this carries an end date from the old
    # `before_create` — thirty days after signup, for most of them long past —
    # and nothing ever read it. The new rule turns that column into something
    # with teeth, so leaving those dates in place would put every existing
    # customer into read-only the moment this deploys.
    Account.where.not(trial_end_at: nil).update_all(trial_end_at: nil, trial_used: false)
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
