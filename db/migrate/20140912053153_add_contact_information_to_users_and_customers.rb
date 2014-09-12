class AddContactInformationToUsersAndCustomers < ActiveRecord::Migration
  def up
    add_column :users, :contact_information, :hstore
    add_column :customers, :contact_information, :hstore

    Address.all.each do |address|
      resource = address.resource
      resource.company = address.company
      resource.name = address.name
      resource.address = address.address
      resource.country = address.country
      if resource.is_a?(User)
        resource.public_email = address.email
      else
        resource.email = address.email
      end
      resource.telefon = address.telefon
      resource.fax = address.fax
      resource.website = address.website
      resource.save
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "Wont go back to plain ids"
  end
end
