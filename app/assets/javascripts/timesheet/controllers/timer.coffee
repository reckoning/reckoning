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

    window.App.cable.subscriptions.create
      channel: 'TimersChannel',
      room: $scope.date
    ,
      connected: () ->
        console.log('connected')
      received: () ->
        console.log('update')
        if !$scope.startedAction
          $scope.getTimers()
        else
          $scope.startedAction = false

    $scope.isStartable = (date) -> Timer.isStartable(date)

    $scope.openModal = (timer) ->
      $scope.startedAction = true
      modalTimer = {date: @date, started: true}
      if timer isnt undefined
        angular.copy(timer, modalTimer)
      $uibModal.open
        templateUrl: Routes.timer_modal_timesheets_template_path()
        controller: 'TimerModalController'
        resolve:
          timer: -> modalTimer
          projects: -> Project.all(sort: "used")
          excludedTaskUuids: -> []
          withoutProjectSelect: -> false
      .result.then (result) ->
        setTimeout ->
          $scope.startedAction = false
        , 2000

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
      $scope.startedAction = true
      Timer.start(timer.uuid).success (data) ->
        $scope.timers.forEach (item) ->
          item.started = false
        timer.started = data.started
        timer.startTime = data.startTime
        timer.startedAt = data.startedAt

        setTimeout ->
          $scope.startedAction = false
        , 2000

    $scope.stopTimer = (timer) ->
      $scope.startedAction = true
      Timer.stop(timer.uuid).success (data) ->
        timer.value = data.value
        timer.started = data.started
        timer.startedAt = data.startedAt

        setTimeout ->
          $scope.startedAction = false
        , 2000

    if $routeParams.action == "new"
      $scope.openModal()

    $scope.$watch 'timersLoaded', ->
      if $routeParams.action == "edit"
        timer = _.find $scope.timers, (item) -> item.uuid is $routeParams.id
        return unless timer
        $scope.openModal(timer)
]
