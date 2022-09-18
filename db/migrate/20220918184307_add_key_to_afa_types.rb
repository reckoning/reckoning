class AddKeyToAfaTypes < ActiveRecord::Migration[6.1]
  def change
    add_column :afa_types, :key, :string
  end
end
