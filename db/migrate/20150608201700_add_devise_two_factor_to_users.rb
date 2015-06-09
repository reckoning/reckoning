class AddDeviseTwoFactorToUsers < ActiveRecord::Migration
  def change
    add_column :users, :encrypted_otp_secret, :string
    add_column :users, :encrypted_otp_secret_iv, :string
    add_column :users, :encrypted_otp_secret_salt, :string
    add_column :users, :otp_required_for_login, :boolean

    User.all.each do |user|
      user.otp_secret = User.generate_otp_secret
      user.save!
    end
  end
end
