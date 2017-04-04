window.App.Timer =
  intervalId: null
  timer: null
  update: =>
    $valueElement = $('[data-timer-started-at]').find('.timer-value')
    timer = App.Timer.timer
    now = moment()
    startedAt = moment(timer.startedAt)
    duration = moment.duration(now.diff(startedAt));

    initialValue = parseFloat(timer.value)

    $valueElement.html(App.Timer.transform(initialValue + duration.asHours()))

  transform: (input) ->
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

document.addEventListener 'turbolinks:load', ->
  if $('[data-timer-started-at]').length
    $element = $('[data-timer-started-at]')

    App.Timer.timer =
      date: $element.data('timer-date')
      startedAt: $element.data('timer-started-at')
      value: $element.data('timer-value')

    App.Timer.intervalId = setInterval(App.Timer.update, 5000)

    window.App.cable.subscriptions.create
      channel: 'TimersChannel',
      room: App.Timer.timer.date
    ,
      connected: ->
        console.log('connected')
      received: (data) ->
        console.log('update')
        App.Timer.timer = JSON.parse(data)
        if App.Timer.timer.startedAt
          App.Timer.element.show()
          App.Timer.intervalId = setInterval(App.Timer.update, 5000)
        else
          App.Timer.element.hide()
          clearInterval(App.Timer.intervalId)
