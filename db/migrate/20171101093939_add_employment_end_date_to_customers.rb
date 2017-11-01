class AddEmploymentEndDateToCustomers < ActiveRecord::Migration[5.1]
  def change
    add_column :customers, :employment_end_date, :date
  end
end
