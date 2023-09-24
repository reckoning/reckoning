class App.Timer
  container: null
  intervalId: null
  timer: null
  element: null
  constructor: (container) ->
    @container = container
    @element = @container.find('.timer')

  init: ->
    newTimer = @element.data('timer')
    if newTimer
      @set(newTimer)

    @setupVisibilityCheck()
    @setupCable()

  setupVisibilityCheck: ->
    document.addEventListener("visibilitychange", @visibilitychange)
    document.addEventListener("mozvisibilitychange", @visibilitychange)
    document.addEventListener("webkitvisibilitychange", @visibilitychange)
    document.addEventListener("msvisibilitychange", @visibilitychange)
    document.onfocusin = @visibilitychange
    window.onpageshow = @visibilitychange

  visibilitychange: (evt) =>
    now = new Date().getTime()
    console.log('Page View')
    fetchInterval = 15 * (60 * 1000) #only fetch after 15 mins.
    if now - @lastVisibilityTrigger > fetchInterval
      @lastVisibilityTrigger = now
      console.log('Reloading Running Timer')
      @fetch()
      if App.cable.connection.disconnected
        @setupCable()
    else
      @lastVisibilityTrigger = now

  setupCable: ->
    App.cable.subscriptions.create
      channel: 'TimersChannel'
      room: 'all'
    ,
      connected: @connected
      received: @received

  connected: =>
    console.log('Timer connected')
    @fetch()

  received: (data) =>
    console.log('Timer received')
    newTimer = JSON.parse(data)
    if newTimer.deleted
      @remove()
    else if newTimer.startedAt
      @set(newTimer)
    else if @timer && newTimer.id == @timer.id
      @remove()

  fetch: ->
    fetch ApiBasePath + "/api/v1/timers?running=true",
      headers: ApiHeaders
    .then (response) ->
      response.json()
    .then (data) =>
      @timer = data[0] if data.length > 0

  set: (timer) ->
    clearInterval(@intervalId) if @intervalId

    @timer = timer

    @update()

    $projectElement = @container.find('.timer-project')
    $projectElement.html(timer.projectName)
    @container.show()

    @intervalId = setInterval =>
      @update()
    , 1000

  remove: ->
    @container.hide()
    clearInterval(@intervalId) if @intervalId

  update: ->
    timer = @timer
    $valueElement = @element.find('.timer-value')

    now = moment()
    startedAt = moment(timer.startedAt)
    duration = moment.duration(now.diff(startedAt));

    initialValue = parseFloat(timer.value)

    $valueElement.html(@transform(initialValue + duration.asHours()))

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
