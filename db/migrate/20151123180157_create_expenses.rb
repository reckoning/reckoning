class CreateExpenses < ActiveRecord::Migration
  def change
    create_table :expenses, id: :uuid, default: "uuid_generate_v4()", force: :cascade do |t|
      t.string :expense_type, null: false
      t.decimal :value, precision: 10, scale: 2, default: 0.0, null: false
      t.string :description
      t.datetime :date, null: false
      t.uuid :account_id, null: false
      t.string :receipt

      t.timestamps null: false
    end
  end
end
