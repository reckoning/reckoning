module InvoicesHelper
  def invoices_sum(invoices)
    sum = 0
    invoices.each do |invoice|
      sum += invoice.value
    end
    sum
  end
end
