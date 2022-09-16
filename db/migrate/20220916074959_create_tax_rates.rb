class CreateTaxRates < ActiveRecord::Migration[6.1]
  def change
    create_table :tax_rates, id: :uuid do |t|
      t.uuid :account_id
      t.decimal :value, precision: 10, scale: 2, default: "0.0", null: false
      t.datetime :valid_from, null: false
      t.datetime :valid_until

      t.timestamps
    end
  end
end
