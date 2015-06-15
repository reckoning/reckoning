angular.module 'Timesheet'
.controller 'TimerController', [
  '$scope'
  'Timer'
  'Project'
  '$modal'
  '$timeout'
  ($scope, Timer, Project, $modal, $timeout) ->
    $scope.timers = []
    $scope.timersLoaded = false
    $scope.currentTasks = []

    $scope.openModal = (timer) ->
      modalTimer = {date: @date, started: true}
      if timer isnt undefined
        angular.copy(timer, modalTimer)
      $modal.open
        templateUrl: Routes.timer_modal_template_timesheet_path()
        controller: 'TimerModalController'
        resolve:
          timer: -> modalTimer
          projects: -> Project.all(sort: "last_used")
          excludedTaskUuids: -> []
      .result.then (result) ->
        if result.status is 'deleted'
          $scope.timers.splice($scope.timers.indexOf(result.data), 1)
        else if result.status is 'updated'
          timer.value = result.data.value
          timer.date = result.data.date
          timer.task_uuid = result.data.task_uuid
          timer.project_uuid = result.data.project_uuid
          timer.note = result.data.note
        else if result.status is 'created'
          $scope.timers.forEach (item) ->
            item.started = false
          $scope.timers.push result.data

    $scope.getTimers = ->
      Timer.all(@date).success (data, status, headers, config) ->
        $scope.timers = data
        data.forEach (timer) ->
          task = {uuid: timer.task_uuid}
          $scope.currentTasks.push task
        $scope.timersLoaded = true

    $scope.getTimers()

    $scope.startedValue = (timer) ->
      ms = moment().diff(moment(timer.started_at))
      moment.duration(ms).asHours() + parseFloat(timer.value)

    $scope.startTimer = (timer) ->
      Timer.start(timer.uuid).success (data) ->
        $scope.timers.forEach (item) ->
          item.started = false
        timer.started = data.started
        timer.start_time = data.start_time
        timer.started_at = data.started_at

    $scope.stopTimer = (timer) ->
      Timer.stop(timer.uuid).success (data) ->
        timer.value = data.value
        timer.started = data.started
        timer.started_at = data.started_at
]
