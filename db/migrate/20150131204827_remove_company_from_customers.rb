class RemoveCompanyFromCustomers < ActiveRecord::Migration
  def up
    Customer.all.each do |customer|
      customer.name = customer.company unless customer.name.present?
      customer.contact_information = customer.contact_information.except("name", "company")
      customer.save!
    end

    remove_column :customers, :company
  end

  def down
  end
end
