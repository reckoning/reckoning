class CreatePlans < ActiveRecord::Migration
  def change
    create_table :plans, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :code
      t.decimal :base_price
      t.integer :quantity
      t.string :interval
      t.integer :discount
      t.boolean :featured
      t.string :stripe_plan_id

      t.timestamps null: false
    end
  end
end
