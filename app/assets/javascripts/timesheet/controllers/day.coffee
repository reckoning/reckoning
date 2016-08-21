angular.module 'Timesheet'
.controller 'DayController', [
  '$scope'
  '$routeParams'
  '$location'
  ($scope, $routeParams, $location) ->
    date = moment().format('YYYY-MM-DD')
    if $routeParams.date && moment($routeParams.date).isValid()
      date = $routeParams.date
    $scope.date = date
    $scope.currentDate = moment().format('YYYY-MM-DD')
    $scope.datepickerSelect = $scope.date

    $scope.$watch 'datepickerSelect', ->
      if $scope.datepickerSelect && $scope.datepickerSelect isnt $scope.date
        $location.path('/day/' + $scope.datepickerSelect)

    $scope.projectPath = (projectId) ->
      Routes.project_path(projectId)

    $scope.navigateToToday = () ->
      $location.path('/day/')

    $scope.day = ->
      date = moment($scope.date)
      date.format('dddd - D. MMMM YYYY')

    $scope.weekDate = ->
      date = moment(@date)
      date.startOf('isoWeek').format('YYYY-MM-DD')

    $scope.startOfWeek = ->
      date = moment($scope.date)
      date.startOf('isoWeek').format('YYYY-MM-DD')

    $scope.nextDay = ->
      moment($scope.date).add(1, 'day').format('YYYY-MM-DD')

    $scope.prevDay = ->
      moment($scope.date).subtract(1, 'day').format('YYYY-MM-DD')
]
