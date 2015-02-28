angular.module 'Timesheet'
.controller 'TimerController', ['$scope', 'Timer', ($scope, Timer) ->
    $scope.timers = []
    $scope.currentTasks = []

    $scope.getTimers = ->
      Timer.all(@date).success (data, status, headers, config) ->
        $scope.timers = data
        data.forEach (timer) ->
          task = {uuid: timer.taskUuid}
          $scope.currentTasks.push task

    $scope.getTimers()

    $scope.refresh = ->
      @getTimers()

    $scope.startedValue = (timer) ->
      ms = moment().diff(moment(timer.startedAt))
      moment.duration(ms).asHours() + parseFloat(timer.value)

    $scope.startTimer = (timer) ->
      Timer.start(timer.uuid).success (data) ->
        $scope.refresh()

    $scope.stopTimer = (timer) ->
      Timer.stop(timer.uuid).success (data) ->
        $scope.refresh()

    $scope.deleteTimer = (timer) ->
      confirm I18n.t('messages.confirm.timesheet.delete_timer'), ->
        Timer.delete(timer.uuid).success (data) ->
          $scope.refresh()
]
