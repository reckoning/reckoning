class CreateAfaTypes < ActiveRecord::Migration[6.1]
  def change
    create_table :afa_types, id: :uuid do |t|
      t.integer :value, null: false
      t.date :valid_from, null: false
      t.date :valid_until

      t.timestamps
    end
  end
end
