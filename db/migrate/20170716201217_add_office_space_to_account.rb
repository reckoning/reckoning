class AddOfficeSpaceToAccount < ActiveRecord::Migration[5.1]
  def change
    add_column :accounts, :office_space, :integer
    add_column :accounts, :deductible_office_space, :integer
    add_column :accounts, :deductible_office_percent, :integer
  end
end
