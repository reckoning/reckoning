# frozen_string_literal: true

json.partial! partial: "api/v1/invoices/show", collection: @invoices, as: :invoice
