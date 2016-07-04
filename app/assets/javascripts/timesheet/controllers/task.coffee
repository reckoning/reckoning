angular.module 'Timesheet'
.controller 'TaskController', [
  '$scope'
  '$filter'
  '$timeout'
  '$uibModal'
  'Timer'
  'Task'
  'Project'
  ($scope, $filter, $timeout, $uibModal, Timer, Task, Project) ->
    $scope.currentTasks = []
    $scope.currentTasksLoaded = false
    $scope.excludedTaskUuids = []

    $scope.openModal = ->
      $uibModal.open
        templateUrl: Routes.task_modal_template_timesheet_path()
        controller: 'TimerModalController'
        resolve:
          timer: -> {date: $scope.date}
          projects: -> Project.all(sort: "last_used")
          excludedTaskUuids: -> $scope.excludedTaskUuids
      .result.then (data) ->
        task = Task.new($scope.dates, data)
        $scope.excludedTaskUuids.push task.uuid
        $scope.currentTasks.push task

    $scope.getTasks = ->
      Task.all(@dates).success (tasks) ->
        $scope.currentTasks = tasks
        tasks.forEach (task) ->
          $scope.excludedTaskUuids.push task.uuid if !_.contains($scope.excludedTaskUuids, task.uuid)
        $scope.currentTasksLoaded = true
    $scope.getTasks()

    $scope.save = (timer) ->
      if timer.sumForTask && timer.sumForTask isnt 0
        timer.value = @calculateTimerValue(timer)
        if timer.uuid
          Timer.update(timer)
        else
          Timer.create(timer).success (newTimer, status, headers, config) ->
            timer.uuid = newTimer.uuid
      else
        if timer.uuid
          Timer.delete(timer.uuid)

    $scope.calculateTimerValue = (timer) ->
      task = _.find @currentTasks, (task) -> task.uuid is timer.taskUuid
      timersForDate = $filter('filter')(task.timers, timer.date, true)
      _.reduce timersForDate, (num, timerForDate) ->
        if timerForDate.uuid is timer.uuid
          num
        else
          num - parseFloat(timerForDate.value)
      , timer.sum_for_task

    $scope.sumForWeek = ->
      sum = 0
      $scope.currentTasks.forEach (task) ->
        task.timers.forEach (timer) ->
          if timer.value
            sum += parseFloat(timer.value, 10)
      sum

    $scope.sumForDate = (date) ->
      sum = 0;
      $scope.currentTasks.forEach (task) ->
        task.timers.forEach (timer) ->
          if timer.date == date.date && timer.value
            sum += parseFloat(timer.value, 10)
      sum

    $scope.sumForTask = (task) ->
      sum = 0
      task.timers.forEach (timer) ->
        if timer.value
          sum += parseFloat(timer.value, 10)
      sum

    $scope.removeTask = (task) ->
      confirm I18n.t('messages.confirm.timesheet.delete_task'), ->
        task.timers.forEach (timer) ->
          if timer.uuid
            Timer.delete(timer.uuid)
        $timeout ->
          $scope.currentTasks.splice($scope.currentTasks.indexOf(task), 1)
          $scope.excludedTaskUuids.splice($scope.excludedTaskUuids.indexOf(task.uuid), 1)
]
