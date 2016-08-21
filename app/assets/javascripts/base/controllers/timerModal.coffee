angular.module 'Reckoning'
.controller 'TimerModalController', [
  '$scope'
  '$timeout'
  '$uibModalInstance'
  'Task'
  'Timer'
  'timer'
  'projects'
  'excludedTaskIds'
  'withoutProjectSelect'
  (
    $scope, $timeout, $uibModalInstance,
    Task, Timer, timer, projects, excludedTaskIds, withoutProjectSelect
  ) ->
    $timeout ->
      $scope.excludedTaskIds = excludedTaskIds
      $scope.withoutProjectSelect = withoutProjectSelect
      $scope.projects = projects.data
      $scope.timer = timer

      if timer.projectId
        project = _.find $scope.projects, (project) ->
          project.id is timer.projectId
        $scope.tasks = project.tasks

    $scope.saveTimer = (timer, start) ->
      return if timer.invoiced || !timer.taskId

      if start
        timer.startedAt = moment()
        timer.startTime = timer.startedAt
          .subtract(timer.value, 'hours').valueOf()
      timer.started = start
      if timer.id
        Timer.update(timer).success (data) ->
          $uibModalInstance.close({data: data, status: 'updated'})
      else
        timer.value = 0 unless timer.value
        Timer.create(timer).success (data) ->
          console.log($uibModalInstance)
          $uibModalInstance.close({data: data, status: 'created'})

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')

    $scope.startTimer = (timer) ->
      Timer.start(timer.id).success (data) ->
        timer.started = data.started
        timer.startTime = data.startTime
        timer.startedAt = data.startedAt

    $scope.stopTimer = (timer) ->
      Timer.stop(timer.id).success (data) ->
        timer.value = data.value
        timer.started = data.started
        timer.startedAt = data.startedAt

    $scope.addTask = ->
      task = _.find $scope.tasks, (task) ->
        task.id is $scope.timer.taskId
      project = _.find $scope.projects, (project) ->
        project.id is $scope.timer.projectId
      task.projectName = project.name
      task.projectCustomerName = project.customerName
      $uibModalInstance.close(task)

    $scope.createTask = (input, selectize) ->
      Task.create(
        projectId: $scope.timer.projectId,
        name: input
      ).success (newTask, status, headers, config) ->
        $timeout ->
          selectize.addOption newTask
          $scope.tasks.push newTask
          selectize.addItem newTask.id

    $scope.delete = (timer) ->
      confirm I18n.t('messages.confirm.timesheet.delete_timer'), ->
        Timer.delete(timer.id).success (data) ->
          $uibModalInstance.close({data: data, status: 'deleted'})

    $scope.isStartable = (date) -> Timer.isStartable(date)

    $scope.$watch 'timer.projectId', ->
      project = _.find $scope.projects, (project) ->
        project.id is $scope.timer.projectId
      $scope.tasks = _.filter project?.tasks, (item) ->
        !_.contains($scope.excludedTaskIds, item.id)
]
