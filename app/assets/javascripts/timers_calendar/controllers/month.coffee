angular.module 'TimersCalendar'
.controller 'MonthController', [
  '$scope'
  '$routeParams'
  '$location'
  '$window'
  '$filter'
  '$timeout'
  '$uibModal'
  'Timer'
  'Project'
  ($scope, $routeParams, $location, $window, $filter, $timeout, $uibModal, Timer, Project) ->
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

    $scope.openModal = (date, timer) ->
      if @isStartable(date)
        modalTimer = {date: date, started: true, projectUuid: @projectUuid}
      else
        modalTimer = {date: date, started: false, projectUuid: @projectUuid}
      if timer isnt undefined
        angular.copy(timer, modalTimer)
      $uibModal.open
        templateUrl: Routes.timer_modal_timesheets_template_path()
        controller: 'TimerModalController'
        resolve:
          timer: -> modalTimer
          projects: -> Project.all(sort: "used")
          excludedTaskUuids: -> []
          withoutProjectSelect: -> true
      .result.then (result) ->
        $scope.getTimers()
      , ->
        $scope.getTimers()

    $scope.isStartable = (date) ->
      moment(date).format('YYYYMMDD') >= moment().format('YYYYMMDD')

    $scope.getTimers = ->
      startDate = moment(@date).startOf('month').startOf('week').format('YYYY-MM-DD')
      endDate = moment(@date).endOf('month').endOf('week').format('YYYY-MM-DD')
      Timer.allInRangeForProject(@projectUuid, startDate, endDate).success (timers) ->
        $scope.currentTimers = timers
        $scope.currentTimersLoaded = true

    $scope.setWeeks = ->
      startDate = moment(@date).startOf('month').startOf('week')
      endDate = moment(@date).endOf('month').endOf('week')
      weekCount = moment(endDate - startDate).weeks() - 1
      date = moment(startDate)
      for weekNumber in [1..weekCount]
        date = date.add(1, 'weeks') if weekNumber > 1
        itr = moment(date.isoWeekday(1)).twix(date.isoWeekday(7)).iterate("days")
        days = []
        while itr.hasNext()
          time = itr.next()
          days.push
            isCurrentMonth: time.format('YYYY-MM') is @date.format('YYYY-MM')
            isCurrentDay: time.format('YYYY-MM-DD') is moment().format('YYYY-MM-DD')
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
      if timer.started
        'running'
      else if timer.positionUuid
        'invoiced'
      else if timer.taskBillable
        'billable'

    $scope.timersForDate = (date) ->
      $filter('filter')(@currentTimers, moment(date).format('YYYY-MM-DD'), true)

    $scope.setWeeks()
    $scope.getTimers()
]
