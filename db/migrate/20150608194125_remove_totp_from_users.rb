class RemoveTotpFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :totp_auth_secret, :string
    remove_column :users, :totp_recovery_secret, :string
    remove_column :users, :totp_enabled, :boolean, default: false, null: false
    remove_column :users, :totp_mandatory, :boolean, default: false, null: false
    remove_column :users, :totp_enabled_on, :datetime
    remove_column :users, :totp_failed_attempts, :integer, default: 0, null: false
    remove_column :users, :totp_recovery_counter, :integer, default: 0, null: false
    remove_column :users, :totp_persistence_seed, :string
    remove_column :users, :totp_session_challenge, :string
    remove_column :users, :totp_challenge_expires, :datetime
  end
end
