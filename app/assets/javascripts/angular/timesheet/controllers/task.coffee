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
    $scope.excludedTaskIds = []

    $scope.openModal = ->
      $uibModal.open
        templateUrl: "/template/task_modal_timesheets"
        controller: 'TimerModalController'
        resolve:
          timer: -> {date: $scope.date}
          projects: -> Project.all(sort: "last_used")
          excludedTaskIds: -> $scope.excludedTaskIds
          withoutProjectSelect: -> false
      .result.then (data) ->
        task = Task.new($scope.dates, data)
        $scope.excludedTaskIds.push task.id
        $scope.currentTasks.push task

    $scope.getTasks = ->
      Task.all(@dates).success (tasks) ->
        $scope.currentTasks = tasks
        tasks.forEach (task) ->
          $scope.excludedTaskIds.push task.id if !_.contains($scope.excludedTaskIds, task.id)
        $scope.currentTasksLoaded = true
    $scope.getTasks()

    $scope.save = (timer) ->
      if timer.sumForTask && timer.sumForTask isnt 0
        timer.value = @calculateTimerValue(timer)
        if timer.id
          Timer.update(timer)
        else
          Timer.create(timer).success (newTimer, status, headers, config) ->
            timer.id = newTimer.id
      else
        if timer.id
          Timer.delete(timer.id)

    $scope.calculateTimerValue = (timer) ->
      task = _.find @currentTasks, (task) -> task.id is timer.taskId
      timersForDate = $filter('filter')(task.timers, timer.date, true)
      _.reduce timersForDate, (num, timerForDate) ->
        if timerForDate.id is timer.id
          num
        else
          num - parseFloat(timerForDate.value)
      , timer.sumForTask

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
          if timer.id
            Timer.delete(timer.id)
        $timeout ->
          $scope.currentTasks.splice($scope.currentTasks.indexOf(task), 1)
          $scope.excludedTaskIds.splice($scope.excludedTaskIds.indexOf(task.id), 1)
]
