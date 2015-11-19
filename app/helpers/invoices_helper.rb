module InvoicesHelper
  def invoices_sum(invoices)
    sum = 0
    invoices.each do |invoice|
      sum += invoice.value
    end
    sum
  end

  def invoice_label(invoice)
    case invoice.current_state.to_s
    when "created"
      "default"
    when "paid"
      "success"
    else
      "primary"
    end
  end
end
