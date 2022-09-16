class AddOfferHeadlineToCustomers < ActiveRecord::Migration[6.1]
  def change
    add_column :customers, :offer_disclaimer, :text
  end
end
