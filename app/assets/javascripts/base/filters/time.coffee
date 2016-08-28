angular.module 'Reckoning'
.filter 'toHours', ->
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
.filter 'toShortDate', ->
  (input) ->
    I18n.l("time.formats.short", input)
.filter 'toTimeInWords', ->
  (input) ->
    time = parseInt(input, 10) / 3600
    hours = Math.floor(time)
    minutes = Math.round((time % 1) * 60)
    result = ""
    if hours > 0
      result += "#{hours} #{I18n.t('hours', { count: hours })} "
    result += "#{minutes} #{I18n.t('minutes', { count: minutes })}"
    result
