class App.Cable
  consumer: null
  constructor: ->
    @consumer = ActionCable.createConsumer()
