class CreateOffers < ActiveRecord::Migration[6.1]
  def change
    create_table :offers, id: :uuid do |t|
      t.uuid :account_id, null: false
      t.uuid :customer_id
      t.uuid :project_id
      t.text :description
      t.date :date
      t.decimal :value, precision: 10, scale: 2, default: "0.0", null: false
      t.decimal :rate, precision: 10, scale: 2, default: "0.0", null: false
      t.string :aasm_state
      t.integer :ref
      t.boolean :pdf_generating, default: false, null: false
      t.datetime :pdf_generated_at

      t.timestamps
    end
  end
end
