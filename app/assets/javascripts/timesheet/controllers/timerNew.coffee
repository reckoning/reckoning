angular.module 'Timesheet'
.controller 'TimerNewController', [
  '$scope'
  'Task'
  'Timer'
  '$modalInstance'
  'timer'
  'projects'
  'excludedTaskUuids'
  ($scope, Task, Timer, $modalInstance, timer, projects, excludedTaskUuids) ->
    $scope.excludedTaskUuids = excludedTaskUuids
    $scope.projects = projects.data
    $scope.timer = timer

    if timer.projectUuid
      project = _.find $scope.projects, (project) -> project.uuid is timer.projectUuid
      $scope.tasks = project.tasks

    $scope.saveTimer = (timer) ->
      if timer.uuid
        Timer.update(timer).success (data) ->
          $modalInstance.close({data: data, status: 'updated'})
      else
        timer.value = 0 unless timer.value
        Timer.createStarted(timer).success (data) ->
          $modalInstance.close({data: data, status: 'created'})

    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

    $scope.addTask = ->
      task = _.find $scope.tasks, (task) -> task.uuid is $scope.timer.taskUuid
      $modalInstance.close(task)

    $scope.createTask = (input, selectize) ->
      Task.create(
        projectUuid: $scope.timer.projectUuid,
        name: input
      ).success (newTask, status, headers, config) ->
        $timeout ->
          selectize.addOption newTask
          selectize.addItem newTask.uuid

    $scope.delete = (timer) ->
      confirm I18n.t('messages.confirm.timesheet.delete_timer'), ->
        Timer.delete(timer.uuid).success (data) ->
          $modalInstance.close({date: data, status: 'deleted'})

    $scope.$watch 'timer.projectUuid', ->
      project = _.find $scope.projects, (project) -> project.uuid is $scope.timer.projectUuid
      $scope.tasks = _.filter project?.tasks, (item) ->
        !_.contains($scope.excludedTaskUuids, item.uuid)
]
