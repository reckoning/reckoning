class AddStripeFieldsToAccounts < ActiveRecord::Migration
  def change
    add_column :accounts, :stripe_email, :string
    add_column :accounts, :stripe_token, :string
  end
end
