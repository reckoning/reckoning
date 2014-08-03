module NumberHelper
  def round_to_k number
    rounded = number.round(-3)
    if rounded < number
      return rounded + 1000
    else
      return rounded
    end
  end
end