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
  ($scope, $timeout, $uibModalInstance, Task, Timer, timer, projects, excludedTaskUuids) ->
    $timeout ->
      $scope.excludedTaskUuids = excludedTaskUuids
      $scope.projects = projects.data
      $scope.timer = timer

      if timer.project_uuid
        project = _.find $scope.projects, (project) -> project.uuid is timer.project_uuid
        $scope.tasks = project.tasks

    $scope.saveTimer = (timer) ->
      if timer.uuid
        Timer.update(timer).success (data) ->
          $uibModalInstance.close({data: data, status: 'updated'})
      else
        timer.value = 0 unless timer.value
        timer.started = false if timer.value > 0
        Timer.create(timer).success (data) ->
          $uibModalInstance.close({data: data, status: 'created'})

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')

    $scope.startTimer = (timer) ->
      Timer.start(timer.uuid).success (data) ->
        timer.started = data.started
        timer.start_time = data.start_time
        timer.started_at = data.started_at

    $scope.stopTimer = (timer) ->
      Timer.stop(timer.uuid).success (data) ->
        timer.value = data.value
        timer.started = data.started
        timer.started_at = data.started_at

    $scope.addTask = ->
      task = _.find $scope.tasks, (task) -> task.uuid is $scope.timer.task_uuid
      $uibModalInstance.close(task)

    $scope.createTask = (input, selectize) ->
      Task.create(
        project_uuid: $scope.timer.project_uuid,
        name: input
      ).success (newTask, status, headers, config) ->
        $timeout ->
          selectize.addOption newTask
          $scope.tasks.push newTask
          selectize.addItem newTask.uuid

    $scope.delete = (timer) ->
      confirm I18n.t('messages.confirm.timesheet.delete_timer'), ->
        console.log
        Timer.delete(timer.uuid).success (data) ->
          $uibModalInstance.close({data: data, status: 'deleted'})

    $scope.$watch 'timer.project_uuid', ->
      project = _.find $scope.projects, (project) -> project.uuid is $scope.timer.project_uuid
      $scope.tasks = _.filter project?.tasks, (item) ->
        !_.contains($scope.excludedTaskUuids, item.uuid)
]
