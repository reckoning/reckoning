# encoding: utf-8
# frozen_string_literal: true
module NumberHelper
  def round_to_k(number)
    rounded = number.round(-3)

    return rounded + 1000 if rounded < number

    rounded
  end
end
