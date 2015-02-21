class DeviseTotpAddToUsers < ActiveRecord::Migration
  def self.up
    change_table :users do |t|
      t.string :totp_auth_secret
      t.string :totp_recovery_secret
      t.boolean :totp_enabled, default: false, null: false
      t.boolean :totp_mandatory, default: false, null: false
      t.datetime :totp_enabled_on
      t.integer :totp_failed_attempts, default: 0, null: false
      t.integer :totp_recovery_counter, default: 0, null: false
      t.string :totp_persistence_seed

      t.string :totp_session_challenge
      t.datetime :totp_challenge_expires
    end
    add_index :users, :totp_session_challenge, unique: true
    add_index :users, :totp_challenge_expires
  end

  def self.down
    change_table :users do |t|
      t.remove :totp_auth_secret, :totp_recovery_secret, :totp_enabled, :totp_mandatory,
               :totp_enabled_on, :totp_session_challenge, :totp_challenge_expires,
               :totp_failed_attempts, :totp_recovery_counter, :totp_persistence_seed
    end
  end
end
