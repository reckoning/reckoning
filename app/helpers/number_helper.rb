# encoding: utf-8
# frozen_string_literal: true

module NumberHelper
  def round_to_k(number)
    rounded = number.round(-3)

    return rounded + 1000 if rounded < number

    rounded
  end

  def to_time(number)
    hours = number.to_i
    minutes = ((number % 1) * 60).to_i
    if hours != 0 || minutes != 0
      padded = if minutes < 10
                 "0#{minutes}"
               else
                 minutes.to_s
               end
      "#{hours}:#{padded}"
    else
      "0:00"
    end
  end
end
