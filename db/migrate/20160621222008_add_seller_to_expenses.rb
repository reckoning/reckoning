class AddSellerToExpenses < ActiveRecord::Migration
  def change
    add_column :expenses, :seller, :string
  end
end
