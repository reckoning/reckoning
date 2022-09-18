# frozen_string_literal: true

class MigrateAfaTypesToDatabaseValues < ActiveRecord::Migration[6.1]
  def up
    Expense.where.not(afa_type_old: nil).find_each do |expense|
      expense.update(
        afa_type_id: AfaType.find_by(value: expense.afa_type_old)&.id
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
