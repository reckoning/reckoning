# frozen_string_literal: true

json.id invoice.id
json.ref invoice.ref
json.ref_number invoice.ref_number
json.title invoice.title
json.state invoice.workflow_state
json.date invoice.date
json.delivery_date invoice.delivery_date
json.payment_due_date invoice.payment_due_date
json.pay_date invoice.pay_date
json.value invoice.value
json.vat invoice.vat
json.customer_id invoice.customer_id
json.customer_name invoice.customer&.name
json.project_id invoice.project_id
json.project_name invoice.project&.name
json.editable invoice.editable?
json.sendable invoice.send_via_mail?
# What *this* user may do with *this* invoice, not what the record allows.
# The two differ: an expired trial reads everything and writes nothing (see
# `Ability#setup_expired_trial_abilities`), and the state machine decides the
# rest. Without this a client can only guess, and guessing means offering
# buttons the endpoint answers with 403.
json.abilities do
  json.charge can?(:charge, invoice)
  json.pay can?(:pay, invoice)
  json.update can?(:update, invoice)
  json.destroy can?(:destroy, invoice)
  json.send_mail invoice.send_via_mail? && can?(:send, invoice)
end
json.positions invoice.positions.order(:created_at) do |position|
  json.partial! "api/v1/invoices/position", position: position
end
json.created_at invoice.created_at
json.updated_at invoice.updated_at
