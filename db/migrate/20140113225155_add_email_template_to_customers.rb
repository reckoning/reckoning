class AddEmailTemplateToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :email_template, :text
  end
end
