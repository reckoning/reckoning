class User < ActiveRecord::Base
  store_accessor :settings, :tax, :tax_ref, :provision
  store_accessor :bank_account, :bank, :account_number, :bank_code, :iban, :bic
  store_accessor :services, :dropbox_user, :dropbox_token
  store_accessor :mailing, :default_from, :signature
  store_accessor :contact_information, :name, :company, :address, :country, :public_email, :telefon, :fax, :website
end

class CreateAccountsForCurrentUsers < ActiveRecord::Migration
  def up
    User.all.each do |user|
      account_name = user.company
      if account_name.blank?
        account_name = user.name
      end
      if account_name.blank?
        account_name = user.email
      end
      account = Account.new(
        name: account_name,
        contact_information: user.contact_information.except("name", "company"),
        settings: user.settings,
        bank_account: user.bank_account,
        services: user.services,
        mailing: user.mailing
      )
      account.save!
      user.account = account
      user.save!
    end
  end

  def down
  end
end
