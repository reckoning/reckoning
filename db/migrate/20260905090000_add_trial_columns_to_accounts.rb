# frozen_string_literal: true

# Added alongside the misspelled `trail_end_at` / `trail_used` rather than
# renamed. `deploy.rb` sets `conditionally_migrate` and restarts only after
# the release is published, so old processes keep serving against the new
# schema for a moment — and the code they are running writes `trail_*` in
# `before_create`. A rename would pull those columns out from under it and
# every signup in that window would fail.
#
# The old pair is dropped in a follow-up, once no running code writes it.
class AddTrialColumnsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :trial_end_at, :datetime, precision: nil
    add_column :accounts, :trial_used, :boolean
  end
end
