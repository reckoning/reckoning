angular.module 'Timesheet'
.controller 'WeekController', [
  '$scope'
  '$routeParams'
  '$timeout'
  'Project'
  ($scope, $routeParams, $timeout, Project) ->
    $scope.date = if $routeParams.date && moment($routeParams.date).isValid() then $routeParams.date else moment().startOf('isoWeek').format('YYYY-MM-DD')
    $scope.currentDate = moment().format('YYYY-MM-DD')
    $scope.dates = []

    $scope.startOfWeek = ->
      date = moment($scope.date)
      date.format('D')

    $scope.dayDate = ->
      if @isCurrentWeek()
        @currentDate
      else
        @date

    $scope.isCurrentWeek = ->
      $scope.date is moment($scope.currentDate).startOf('isoWeek').format('YYYY-MM-DD')

    $scope.endOfWeek = ->
      date = moment($scope.date)
      date.endOf('isoWeek').format('D. MMMM YYYY')

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
          day: time.format('ddd')
          short: time.format('D. MMM')
          isCurrentDate: time.isSame(moment().toDate(), 'day')

    $scope.setDates()
]
