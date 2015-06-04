angular.module 'Timesheet'
.controller 'TimerModalController', [
  '$scope'
  'Task'
  'Timer'
  '$modalInstance'
  'timer'
  'projects'
  'excludedTaskUuids'
  '$timeout'
  ($scope, Task, Timer, $modalInstance, timer, projects, excludedTaskUuids, $timeout) ->
    $scope.excludedTaskUuids = excludedTaskUuids
    $scope.projects = projects.data
    $scope.timer = timer

    if timer.project_uuid
      project = _.find $scope.projects, (project) -> project.uuid is timer.project_uuid
      $scope.tasks = project.tasks

    $scope.saveTimer = (timer) ->
      if timer.uuid
        Timer.update(timer).success (data) ->
          $modalInstance.close({data: data, status: 'updated'})
      else
        timer.value = 0 unless timer.value
        timer.started = false if timer.value > 0
        Timer.create(timer).success (data) ->
          $modalInstance.close({data: data, status: 'created'})

    $scope.cancel = ->
      $modalInstance.dismiss('cancel')

    $scope.addTask = ->
      task = _.find $scope.tasks, (task) -> task.uuid is $scope.timer.task_uuid
      $modalInstance.close(task)

    $scope.createTask = (input, selectize) ->
      Task.create(
        projectUuid: $scope.timer.project_uuid,
        name: input
      ).success (newTask, status, headers, config) ->
        $timeout ->
          selectize.addOption newTask
          $scope.tasks.push newTask
          selectize.addItem newTask.uuid

    $scope.delete = (timer) ->
      confirm I18n.t('messages.confirm.timesheet.delete_timer'), ->
        Timer.delete(timer.uuid).success (data) ->
          $modalInstance.close({date: data, status: 'deleted'})

    $scope.$watch 'timer.project_uuid', ->
      project = _.find $scope.projects, (project) -> project.uuid is $scope.timer.project_uuid
      $scope.tasks = _.filter project?.tasks, (item) ->
        !_.contains($scope.excludedTaskUuids, item.uuid)
]
