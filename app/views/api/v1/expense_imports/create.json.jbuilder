# frozen_string_literal: true

json.count @expenses.size
json.message I18n.t("resources.messages.import.success", resource: I18n.t("resources.expense"))
