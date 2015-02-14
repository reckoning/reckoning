class GenerateSecretsForUsers < ActiveRecord::Migration
  def up
    User.all.each(&:reset_totp_credentials)
  end

  def down
  end
end
