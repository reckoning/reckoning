angular.module 'TimersCalendar'
.controller 'MonthController', [
  '$scope'
  '$routeParams'
  '$location'
  '$window'
  '$filter'
  'Timer'
  ($scope, $routeParams, $location, $window, $filter, Timer) ->
    $scope.projectUuid = $window.projectUuid
    if $routeParams.date && moment($routeParams.date, 'YYYY-MM-DD').isValid()
      $scope.date = moment($routeParams.date, 'YYYY-MM-DD').startOf('month')
    else
      $scope.date = moment().startOf('month')
    $scope.currentDate = moment().format('YYYY-MM-DD')

    $scope.datepickerSelect = $scope.date.format('YYYY-MM-DD')
    $scope.currentTimers = []
    $scope.currentTimersLoaded = false
    $scope.weeks = []

    $scope.getTimers = ->
      startDate = moment(@date).startOf('month').startOf('week').format('YYYY-MM-DD')
      endDate = moment(@date).endOf('month').endOf('week').format('YYYY-MM-DD')
      Timer.allInRangeForProject(@projectUuid, startDate, endDate).success (timers) ->
        console.log timers
        $scope.currentTimers = _.filter timers, (item) ->
          parseFloat(item.value) isnt 0.0
        $scope.currentTimersLoaded = true

    $scope.setWeeks = ->
      endDate = moment(@date).endOf('month')
      weekCount = moment(endDate - @date).weeks()
      date = moment(@date)
      for weekNumber in [1..weekCount]
        date = date.add(1, 'weeks') if weekNumber > 1
        itr = moment(date.isoWeekday(1)).twix(date.isoWeekday(7)).iterate("days")
        days = []
        while itr.hasNext()
          time = itr.next()
          days.push
            isCurrentMonth: time.format('M') is @date.format('M')
            day: time.format('D')
            date: time.format('YYYY-MM-DD')
            dayShort: time.format('dd')

        @weeks.push
          days: days

    $scope.$watch 'datepickerSelect', ->
      if $scope.datepickerSelect && $scope.datepickerSelect isnt $scope.date
        $location.path('/month/' + $scope.datepickerSelect)

    $scope.isCurrentMonth = ->
      currentDate = moment($scope.currentDate).startOf('month')
      date = moment($scope.date).startOf('month')
      date.format('YYYY-MM-DD') is currentDate.format('YYYY-MM-DD')

    $scope.currentMonth = ->
      moment($scope.date).format('MMMM YYYY')

    $scope.nextMonth = ->
      moment($scope.date).add(1, 'month').format('YYYY-MM-DD')

    $scope.prevMonth = ->
      moment($scope.date).subtract(1, 'month').format('YYYY-MM-DD')

    $scope.cssClassForTimer = (timer) ->
      if timer.position_uuid
        'invoiced'
      else if timer.task_billable
        'billable'

    $scope.timersForDate = (date) ->
      $filter('filter')(@currentTimers, moment(date).format('YYYY-MM-DD'), true)

    $scope.setWeeks()
    $scope.getTimers()
]
