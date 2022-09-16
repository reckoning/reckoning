class AddMissingIndexForRefInOffers < ActiveRecord::Migration[6.1]
  def change
    add_index :offers, [:ref, :account_id], unique: true
  end
end
