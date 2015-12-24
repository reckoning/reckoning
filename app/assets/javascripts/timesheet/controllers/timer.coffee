angular.module 'Timesheet'
.controller 'TimerController', [
  '$scope'
  '$routeParams'
  '$uibModal'
  '$timeout'
  'Timer'
  'Project'
  ($scope, $routeParams, $uibModal, $timeout, Timer, Project) ->
    $scope.timers = []
    $scope.timersLoaded = false
    $scope.currentTasks = []

    $scope.openModal = (timer) ->
      modalTimer = {date: @date, started: true}
      if timer isnt undefined
        angular.copy(timer, modalTimer)
      $uibModal.open
        templateUrl: Routes.timer_modal_template_timesheet_path()
        controller: 'TimerModalController'
        resolve:
          timer: -> modalTimer
          projects: -> Project.all(sort: "last_used")
          excludedTaskUuids: -> []
      .result.then (result) ->
        if result.status is 'deleted'
          deletedTimer = _.find $scope.timers, (item) -> item.uuid is result.data.uuid
          $scope.timers.splice($scope.timers.indexOf(deletedTimer), 1)
        else if result.status is 'updated'
          timer.value = result.data.value
          timer.date = result.data.date
          timer.project_uuid = result.data.project_uuid
          timer.project_name = result.data.project_name
          timer.task_uuid = result.data.task_uuid
          timer.task_name = result.data.task_name
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

    if $routeParams.action == "new"
      $scope.openModal()

    $scope.$watch 'timersLoaded', ->
      if $routeParams.action == "edit"
        timer = _.find $scope.timers, (item) -> item.uuid is $routeParams.id
        return unless timer
        $scope.openModal(timer)
]
