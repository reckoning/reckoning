class App.Notifications
  constructor: ->
    App.cable.subscriptions.create
      channel: 'NotificationsChannel'
      room: 'all'
    ,
      connected: @connected
      received: @received

  connected: =>
    console.log('Notifications connected')

  received: (data) =>
    console.log('Notification received')
    notification = JSON.parse(data)
    displayNoty(notification.text, notification.type, false if notification.type is 'error');
