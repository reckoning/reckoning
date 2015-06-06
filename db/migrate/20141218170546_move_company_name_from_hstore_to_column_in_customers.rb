class Customer < ActiveRecord::Base
  store_accessor :contact_information, :name, :company, :address, :country, :email, :telefon, :fax, :website
end

class MoveCompanyNameFromHstoreToColumnInCustomers < ActiveRecord::Migration
  def up
    add_column :customers, :company_name, :string
    add_column :customers, :name_name, :string
    Customer.all.each do |customer|
      customer.company_name = customer.company
      customer.name_name = customer.name
      customer.save
    end
  end

  def down
  end
end
