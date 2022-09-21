class CreateGermanHolidays < ActiveRecord::Migration[6.1]
  def change
    create_table :german_holidays, id: :uuid do |t|
      t.string :name
      t.date :date
      t.string :federal_state

      t.timestamps
    end
  end
end
