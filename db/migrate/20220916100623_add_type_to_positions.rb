class AddTypeToPositions < ActiveRecord::Migration[6.1]
  def change
    add_column :positions, :type, :string
    add_column :positions, :invoicable_id, :uuid
    add_column :positions, :invoicable_type, :string
  end
end
