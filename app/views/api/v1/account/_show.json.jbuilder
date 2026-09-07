# frozen_string_literal: true

json.id account.id
json.name account.name
json.subdomain account.subdomain
json.plan account.plan
json.vat_id account.vat_id
json.tax account.tax
json.provision account.provision
json.bank account.bank
json.account_number account.account_number
json.bank_code account.bank_code
json.iban account.iban
json.bic account.bic
json.default_from account.default_from
json.signature account.signature
json.address account.address
json.country account.country
json.public_email account.public_email
json.telefon account.telefon
json.fax account.fax
json.website account.website
json.office_space account.office_space
json.deductible_office_space account.deductible_office_space
json.offer_headline account.offer_headline
json.feature_expenses account.feature_expenses
json.feature_logbook account.feature_logbook
json.created_at account.created_at
json.updated_at account.updated_at
# A demo deployment caps non-admins at two invoices
# (`ApplicationController#invoice_limit_reached?`). The server-rendered list
# greyed the button out; the SPA cannot know without being told, and being
# bounced back with the flash it never renders is worse than a disabled link.
json.invoice_limit_reached !current_user.admin? && Rails.configuration.app.demo &&
  account.invoices.count >= 2
