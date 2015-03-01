angular.module 'Timesheet'
.controller 'TimerController', [
  '$scope'
  'Timer'
  'Project'
  '$modal'
  ($scope, Timer, Project, $modal) ->
    $scope.timers = []
    $scope.timersLoaded = false
    $scope.currentTasks = []

    $scope.openModal = (timer) ->
      modalTimer = {date: @date, started: true}
      if timer isnt undefined
        angular.copy(timer, modalTimer)
      $modal.open
        templateUrl: r(timer_modal_timesheet_path)
        controller: 'TimerNewController'
        resolve:
          timer: -> modalTimer
          projects: -> Project.all()
          excludedTaskUuids: -> []
      .result.then (data) ->
        $scope.getTimers()

    $scope.getTimers = ->
      Timer.all(@date).success (data, status, headers, config) ->
        $scope.timers = data
        data.forEach (timer) ->
          task = {uuid: timer.taskUuid}
          $scope.currentTasks.push task
        $scope.timersLoaded = true

    $scope.getTimers()

    $scope.startedValue = (timer) ->
      ms = moment().diff(moment(timer.startedAt))
      moment.duration(ms).asHours() + parseFloat(timer.value)

    $scope.startTimer = (timer) ->
      Timer.start(timer.uuid).success (data) ->
        $scope.getTimers()

    $scope.stopTimer = (timer) ->
      Timer.stop(timer.uuid).success (data) ->
        $scope.getTimers()
]
