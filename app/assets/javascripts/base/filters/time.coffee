angular.module 'Reckoning'
.filter 'toHours', ->
  (input) ->
    hours = Math.floor(input)
    minutes = parseInt((input % 1) * 60, 10)
    if minutes <= 0
      tail = '00'
    else if minutes < 10
      tail = '0' + minutes.toString()
    else
      tail = minutes.toString()
    if hours <= 0
      head = 0
    else
      head = hours

    head + ':' + tail

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
