class CreateAccounts < ActiveRecord::Migration
  def change
    create_table :accounts, id: :uuid, default: "uuid_generate_v4()", force: true do |t|
      t.string :name
      t.string :subdomain
      t.string :plan
      t.hstore :settings
      t.hstore :bank_account
      t.hstore :services
      t.hstore :mailing
      t.hstore :contact_information

      t.timestamps null: false
    end

    add_column :users, :account_id, :uuid
  end
end
