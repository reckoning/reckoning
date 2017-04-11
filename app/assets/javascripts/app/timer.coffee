window.App.Timer =
  $containerElement: null
  intervalId: null
  timer: null
  $element: null
  fetch: ->
    fetch ApiBasePath + Routes.v1_timers_path(running: true),
      headers: ApiHeaders
    .then (response) ->
      response.json()
    .then (data) ->
      App.Timer.timer = data[0] if data.length > 0

  setupTimer: (timer) ->
    clearInterval(App.Timer.intervalId) if App.Timer.intervalId

    App.Timer.timer = timer

    App.Timer.update()

    $projectElement = App.Timer.$containerElement.find('.timer-project')
    $projectElement.html(timer.projectName)
    App.Timer.$containerElement.show()

    App.Timer.intervalId = setInterval(App.Timer.update, 1000)

  removeTimer: ->
    App.Timer.$containerElement.hide()
    clearInterval(App.Timer.intervalId) if App.Timer.intervalId

  update: ->
    timer = App.Timer.timer
    $valueElement = App.Timer.$element.find('.timer-value')

    now = moment()
    startedAt = moment(timer.startedAt)
    duration = moment.duration(now.diff(startedAt));

    initialValue = parseFloat(timer.value)

    $valueElement.html(App.Timer.transform(initialValue + duration.asHours()))

  transform: (input) ->
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

document.addEventListener 'turbolinks:load', ->
  App.Timer.$containerElement = $('.current-timers')
  if App.Timer.$containerElement.find('.timer').length
    App.Timer.$element = App.Timer.$containerElement.find('.timer')

    newTimer = App.Timer.$element.data('timer')
    if newTimer
      App.Timer.setupTimer(newTimer)

    App.cable.subscriptions.create
      channel: 'TimersChannel'
      room: 'all'
    ,
      connected: ->
        console.log('connected from timer')
        App.Timer.fetch()
      received: (data) ->
        console.log('update for timer')
        newTimer = JSON.parse(data)
        if newTimer.deleted
          App.Timer.removeTimer()
        else if newTimer.startedAt
          App.Timer.setupTimer(newTimer)
        else if App.Timer.timer && newTimer.id == App.Timer.timer.id
          App.Timer.removeTimer()
