module NumberHelper
  def round_to_k(number)
    number / 1000 * 1000 + 1000
  end
end