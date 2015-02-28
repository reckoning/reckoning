angular.module 'Timesheet'
.controller 'TimerNewController', [
  '$scope'
  '$timeout'
  'Project'
  'Task'
  'Timer'
  ($scope, $timeout, Project, Task, Timer) ->
    $scope.excludedTaskUuids ?= []
    $scope.projects = []
    $scope.tasks = []
    $scope.selectedProject = {}
    $scope.selectedTask = {}

    $scope.getProjects = ->
      Project.all().success (data, status, headers, config) ->
        $scope.projects = data

    $scope.createTimer = ->
      Timer.createStarted($scope.selectedTask.uuid, $scope.date).success (data, status, headers, config) ->
        $scope.refresh()
        $scope.selectedProject = {}
        $scope.selectedTask = {}
        $scope.dismissModal()

    $scope.addTask = ->
      $scope.currentTasks.push Task.new($scope.dates, $scope.selectedTask)
      $scope.dismissModal()

    $scope.createTask = (input, selectize) ->
      Task.create(
        projectUuid: $scope.selectedProject.uuid,
        name: input
      ).success (newTask, status, headers, config) ->
        $timeout ->
          selectize.addOption newTask
          selectize.addItem newTask.uuid

    $scope.afterModalDismiss = (element) ->
      $timeout ->
        element.find('select').each (index, select) ->
          selectize = $(select)[0].selectize
          selectize.clear()

    $scope.$watch 'selectedProject', ->
      $scope.tasks = _.filter $scope.selectedProject?.tasks, (item) ->
        !_.contains($scope.excludedTaskUuids, item.uuid)
]
