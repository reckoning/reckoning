# frozen_string_literal: true

class BackfillInvoicePositions < ActiveRecord::Migration[6.1]
  def up
    Invoice.find_each do |invoice|
      Position.where(invoice_id: invoice.id).find_each do |position|
        position.update(invoicable: invoice, type: "InvoicePosition")
      end
    end
  end

  def down
  end
end
