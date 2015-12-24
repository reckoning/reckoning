angular.module 'Reckoning'
.filter 'toTime', ->
  (input) ->
    hours = Math.floor(input)
    minutes = Math.round((input % 1) * 60)
    if hours isnt 0 || minutes isnt 0
      if minutes < 10
        padded = '0' + minutes.toString()
      else
        padded = minutes.toString()
      hours + ':' + padded
    else
      '0:00'
