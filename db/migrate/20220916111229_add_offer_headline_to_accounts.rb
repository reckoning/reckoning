class AddOfferHeadlineToAccounts < ActiveRecord::Migration[6.1]
  def change
    add_column :accounts, :offer_headline, :text
  end
end
