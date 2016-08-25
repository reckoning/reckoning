angular.module 'Logbook'
.controller 'LogbookController', [
  '$scope'
  '$uibModal'
  '$routeParams'
  '$location'
  'Tour'
  'Vessel'
  'User'
  ($scope, $uibModal, $routeParams, $location, Tour, Vessel, User) ->
    date = moment().format('YYYY-MM-DD')
    if $routeParams.date && moment($routeParams.date).isValid()
      date = $routeParams.date
    $scope.date = date
    $scope.datepickerSelect = $scope.date

    $scope.$watch 'datepickerSelect', ->
      if $scope.datepickerSelect && $scope.datepickerSelect isnt $scope.date
        $location.path('/day/' + $scope.datepickerSelect)

    $scope.openModal = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $uibModal.open
        templateUrl: Routes.tour_modal_logbooks_template_path()
        controller: 'TourModalController'
        resolve:
          tour: -> Tour.new()
          vessels: -> Vessel.all()
          drivers: -> User.all()
          currentUser: -> User.current()
      .result.then ->
        $scope.$broadcast('tourStarted')

    $scope.day = ->
      date = moment($scope.date)
      I18n.l("date.formats.timesheet_day", date.toDate())

    $scope.navigateToToday = () ->
      $location.path('/day/')

    $scope.nextDay = ->
      moment($scope.date).add(1, 'day').format('YYYY-MM-DD')

    $scope.prevDay = ->
      moment($scope.date).subtract(1, 'day').format('YYYY-MM-DD')
]
