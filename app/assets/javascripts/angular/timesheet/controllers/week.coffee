angular.module 'Timesheet'
.controller 'WeekController', [
  '$scope'
  '$routeParams'
  '$location'
  ($scope, $routeParams, $location) ->
    $scope.date = if $routeParams.date && moment($routeParams.date).isValid() then $routeParams.date else I18n.l("date.formats.db", moment().startOf('isoWeek').toDate())
    $scope.currentDate = I18n.l("date.formats.db", moment().toDate())
    $scope.datepickerSelect = $scope.date
    $scope.dates = []

    $scope.startOfWeek = ->
      date = moment($scope.date)
      I18n.l("date.formats.day_number", date.startOf('isoWeek').toDate())

    $scope.navigateToToday = () ->
      $location.path('/week/')

    $scope.dayDate = ->
      if @isCurrentWeek()
        @currentDate
      else
        @date

    $scope.projectPath = (projectId) ->
      Routes.project_path(projectId)

    $scope.$watch 'datepickerSelect', ->
      if $scope.datepickerSelect
        $location.path('/week/' + $scope.datepickerSelect)

    $scope.isCurrentWeek = ->
      date = moment($scope.date)
      date.startOf('isoWeek').format('YYYY-MM-DD') is moment($scope.currentDate).startOf('isoWeek').format('YYYY-MM-DD')

    $scope.endOfWeek = ->
      date = moment($scope.date)
      I18n.l("date.formats.timesheet_week", date.endOf('isoWeek').toDate())

    $scope.currentWeek = ->
      $scope.date = moment().startOf('isoWeek').format('YYYY-MM-DD')

    $scope.nextWeek = ->
      moment($scope.date).add(1, 'weeks').format('YYYY-MM-DD')

    $scope.prevWeek = ->
      moment($scope.date).subtract(1, 'weeks').format('YYYY-MM-DD')

    $scope.setDates = ->
      $scope.dates = []
      date = moment($scope.date)
      itr = moment(date.isoWeekday(1)).twix(date.isoWeekday(7)).iterate("days")

      while itr.hasNext()
        time = itr.next()
        $scope.dates.push
          date: time.format('YYYY-MM-DD')
          day: I18n.l("date.formats.day_short", time.toDate())
          short: I18n.l("date.formats.timesheet_day_short", time.toDate())
          isCurrentDate: time.isSame(moment().toDate(), 'day')

    $scope.setDates()
]
