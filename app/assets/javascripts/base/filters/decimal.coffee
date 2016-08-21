angular.module 'Reckoning'
.filter 'hoursToDecimal', ->
  (input) ->
    parts = input.split(':')
    time = parseInt(parts[0], 10) + (parseInt(parts[1], 10) / 60)
    newInput = parseFloat(time)
    if isNaN(newInput)
      "#{input}"
    else
      "#{newInput}"
.filter 'toDecimal', ->
  (input) ->
    if input
      parseFloat(input, 10)
    else
      null
