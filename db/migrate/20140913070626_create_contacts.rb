class CreateContacts < ActiveRecord::Migration
  def change
    create_table :contacts, id: :uuid do |t|
      t.string :email

      t.timestamps
    end
  end
end
