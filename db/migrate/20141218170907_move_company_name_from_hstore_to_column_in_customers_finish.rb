class Customer < ActiveRecord::Base
  store_accessor :contact_information, :address, :country, :email, :telefon, :fax, :website
end

class MoveCompanyNameFromHstoreToColumnInCustomersFinish < ActiveRecord::Migration
  def up
    remove_column :customers, :name
    rename_column :customers, :company_name, :company
    rename_column :customers, :name_name, :name
  end

  def down

  end
end
