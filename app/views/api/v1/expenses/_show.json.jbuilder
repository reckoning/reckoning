# frozen_string_literal: true

json.id expense.id
json.expense_type expense.expense_type
json.description expense.description
json.seller expense.seller
json.date expense.date
json.value expense.value
json.usable_value expense.usable_value
json.vat_percent expense.vat_percent
json.vat_value expense.vat_value
json.private_use_percent expense.private_use_percent
json.interval expense.interval
json.started_at expense.started_at
json.ended_at expense.ended_at
json.afa_type_id expense.afa_type_id
json.has_receipt expense.receipt.attached?
json.needs_receipt expense.needs_receipt?
json.created_at expense.created_at
json.updated_at expense.updated_at
