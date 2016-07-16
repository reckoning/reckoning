angular.module 'Timesheet'
.controller 'TimerController', [
  '$scope'
  '$routeParams'
  '$uibModal'
  '$timeout'
  '$window'
  'Timer'
  'Project'
  ($scope, $routeParams, $uibModal, $timeout, $window, Timer, Project) ->
    $scope.timers = []
    $scope.timersLoaded = false
    $scope.currentTasks = []

    $window.onfocus = ->
      return if !$scope.date
      Timer.all($scope.date).success (data, status, headers, config) ->
        data.forEach (timer) ->
          found = $scope.timers.find((item) -> item.uuid is timer.uuid)
          if found
            Timer.updateData(found, timer)
          else
            $scope.timers.push timer

    $scope.isStartable = (date) -> Timer.isStartable(date)

    $scope.openModal = (timer) ->
      modalTimer = {date: @date, started: true}
      if timer isnt undefined
        angular.copy(timer, modalTimer)
      $uibModal.open
        templateUrl: Routes.timer_modal_timesheets_template_path()
        controller: 'TimerModalController'
        resolve:
          timer: -> modalTimer
          projects: -> Project.all(sort: "last_used")
          excludedTaskUuids: -> []
          withoutProjectSelect: -> false
      .result.then (result) ->
        if result.status is 'deleted'
          deletedTimer = _.find $scope.timers, (item) ->
            item.uuid is result.data.uuid
          $scope.timers.splice($scope.timers.indexOf(deletedTimer), 1)
        else if result.status is 'updated'
          Timer.updateData(timer, result.data)
        else if result.status is 'created'
          $scope.timers.forEach (item) ->
            item.started = false
          $scope.timers.push result.data

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
        $scope.timers.forEach (item) ->
          item.started = false
        timer.started = data.started
        timer.startTime = data.startTime
        timer.startedAt = data.startedAt

    $scope.stopTimer = (timer) ->
      Timer.stop(timer.uuid).success (data) ->
        timer.value = data.value
        timer.started = data.started
        timer.startedAt = data.startedAt

    if $routeParams.action == "new"
      $scope.openModal()

    $scope.$watch 'timersLoaded', ->
      if $routeParams.action == "edit"
        timer = _.find $scope.timers, (item) -> item.uuid is $routeParams.id
        return unless timer
        $scope.openModal(timer)
]
