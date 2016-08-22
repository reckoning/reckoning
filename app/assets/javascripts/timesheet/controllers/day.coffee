angular.module 'Timesheet'
.controller 'DayController', [
  '$scope'
  '$routeParams'
  '$location'
  ($scope, $routeParams, $location) ->
    date = I18n.l("date.formats.db", moment().toDate())
    if $routeParams.date && moment($routeParams.date).isValid()
      date = $routeParams.date
    $scope.date = date
    $scope.currentDate = I18n.l("date.formats.db", moment().toDate())
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
      I18n.l("date.formats.timesheet_day", date.toDate())

    $scope.weekDate = ->
      date = moment(@date)
      I18n.l("date.formats.db", date.startOf('isoWeek').toDate())

    $scope.startOfWeek = ->
      date = moment($scope.date)
      I18n.l("date.formats.db", date.startOf('isoWeek').toDate())

    $scope.nextDay = ->
      I18n.l("date.formats.db", moment($scope.date).add(1, 'day').toDate())

    $scope.prevDay = ->
      I18n.l("date.formats.db", moment($scope.date).subtract(1, 'day').toDate())
]
