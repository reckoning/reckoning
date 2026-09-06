# frozen_string_literal: true

# Added alongside the misspelled `trail_end_at` / `trail_used` rather than
# renamed. `deploy.rb` sets `conditionally_migrate` and restarts only after the
# release is published, so old processes keep serving against the new schema
# for a moment — and the code they are running writes `trail_*` in
# `before_create`. A rename would pull those columns out from under it and
# every signup in that window would fail.
#
# The old pair is dropped in a follow-up, once no running code writes it.
class AddTrialColumnsToAccounts < ActiveRecord::Migration[8.1]
  def up
    add_column :accounts, :trial_end_at, :datetime, precision: nil
    add_column :accounts, :trial_used, :boolean

    # The defaults are set *after* the columns exist, so existing rows keep
    # NULL — no trial, full access, which is what they have had all along.
    # From here on they only apply to an INSERT that does not name these
    # columns, and there is exactly one thing that does that: the old release
    # during the deploy window, whose schema cache predates them. Without this
    # an account created in those seconds would come out with no trial and
    # never lose write access.
    #
    # New code cannot trip over them: `partial_inserts` is false, so it writes
    # every column explicitly and a free-plan account still lands with NULL.
    # Keep the interval in step with `Account::TRIAL_LENGTH`.
    change_column_default :accounts, :trial_end_at, from: nil, to: -> { "now() + interval '14 days'" }
    change_column_default :accounts, :trial_used, from: nil, to: true
  end

  def down
    remove_column :accounts, :trial_end_at
    remove_column :accounts, :trial_used
  end
end
