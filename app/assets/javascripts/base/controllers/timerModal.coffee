angular.module 'Reckoning'
.controller 'TimerModalController', [
  '$scope'
  '$timeout'
  '$uibModalInstance'
  'Task'
  'Timer'
  'timer'
  'projects'
  'excludedTaskUuids'
  'withoutProjectSelect'
  (
    $scope, $timeout, $uibModalInstance,
    Task, Timer, timer, projects, excludedTaskUuids, withoutProjectSelect
  ) ->
    $timeout ->
      $scope.excludedTaskUuids = excludedTaskUuids
      $scope.withoutProjectSelect = withoutProjectSelect
      $scope.projects = projects.data
      $scope.timer = timer

      if timer.projectUuid
        project = _.find $scope.projects, (project) ->
          project.uuid is timer.projectUuid
        $scope.tasks = project.tasks

    $scope.saveTimer = (timer, start) ->
      if timer.uuid
        timer.started = start
        Timer.update(timer).success (data) ->
          $uibModalInstance.close({data: data, status: 'updated'})
      else
        timer.value = 0 unless timer.value
        timer.started = start
        Timer.create(timer).success (data) ->
          $uibModalInstance.close({data: data, status: 'created'})

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')

    $scope.startTimer = (timer) ->
      Timer.start(timer.uuid).success (data) ->
        timer.started = data.started
        timer.startTime = data.startTime
        timer.startedAt = data.startedAt

    $scope.stopTimer = (timer) ->
      Timer.stop(timer.uuid).success (data) ->
        timer.value = data.value
        timer.started = data.started
        timer.startedAt = data.startedAt

    $scope.addTask = ->
      task = _.find $scope.tasks, (task) ->
        task.uuid is $scope.timer.taskUuid
      project = _.find $scope.projects, (project) ->
        project.uuid is $scope.timer.projectUuid
      task.projectName = project.name
      task.projectCustomerName = project.customerName
      $uibModalInstance.close(task)

    $scope.createTask = (input, selectize) ->
      Task.create(
        projectUuid: $scope.timer.projectUuid,
        name: input
      ).success (newTask, status, headers, config) ->
        $timeout ->
          selectize.addOption newTask
          $scope.tasks.push newTask
          selectize.addItem newTask.uuid

    $scope.delete = (timer) ->
      confirm I18n.t('messages.confirm.timesheet.delete_timer'), ->
        Timer.delete(timer.uuid).success (data) ->
          $uibModalInstance.close({data: data, status: 'deleted'})

    $scope.isStartable = (date) -> Timer.isStartable(date)

    $scope.$watch 'timer.projectUuid', ->
      project = _.find $scope.projects, (project) ->
        project.uuid is $scope.timer.projectUuid
      $scope.tasks = _.filter project?.tasks, (item) ->
        !_.contains($scope.excludedTaskUuids, item.uuid)
]
