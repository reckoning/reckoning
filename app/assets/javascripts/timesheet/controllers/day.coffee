angular.module 'Timesheet'
.controller 'DayController', [
  '$scope'
  '$routeParams'
  '$timeout'
  'Project'
  ($scope, $routeParams, $timeout, Project) ->
    $scope.date = if $routeParams.date && moment($routeParams.date).isValid() then $routeParams.date else moment().format('YYYY-MM-DD')
    $scope.currentDate = moment().format('YYYY-MM-DD')

    $scope.day = ->
      date = moment($scope.date)
      date.format('dddd - D. MMMM YYYY')

    $scope.isCurrentDay = ->
      $scope.date is $scope.currentDate

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
