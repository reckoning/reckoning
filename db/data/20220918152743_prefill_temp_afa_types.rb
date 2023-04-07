# frozen_string_literal: true

class PrefillTempAfaTypes < ActiveRecord::Migration[6.1]
  def up
    I18n.locale = :de
    [{
      value: 3,
      label: I18n.t("expenses.afa_types.computer")
    }, {
      value: 5,
      label: I18n.t("expenses.afa_types.smartphone")
    }, {
      value: 7,
      label: I18n.t("expenses.afa_types.tv")
    }, {
      value: 7,
      label: I18n.t("expenses.afa_types.bicycle")
    }, {
      value: 13,
      label: I18n.t("expenses.afa_types.office_furniture")
    }].each do |afa_type|
      AfaType.create!(
        value: afa_type[:value],
        name: afa_type[:label],
        valid_from: Date.new(1970, 1, 1)
      )
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
