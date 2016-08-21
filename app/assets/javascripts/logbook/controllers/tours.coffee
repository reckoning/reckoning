angular.module 'Logbook'
.controller 'ToursController', [
  '$scope'
  '$uibModal'
  'Tour'
  'Waypoint'
  'User'
  ($scope, $uibModal, Tour, Waypoint, User) ->
    $scope.tours = []
    $scope.toursLoaded = false

    $scope.getTours = ->
      Tour.all(@date).then (tours) ->
        $scope.tours = tours
        $scope.toursLoaded = true

    $scope.getTours()

    $scope.$on 'tourStarted', ->
      $scope.getTours()

    $scope.openModal = (tour) ->
      waypoint = {
        tourId: tour.id
        milage: tour.vesselMilage
        driverId: tour.lastDriverId
      }
      $uibModal.open
        templateUrl: Routes.waypoint_modal_logbooks_template_path()
        controller: 'WaypointModalController'
        resolve:
          minimumMilage: -> tour.vesselMilage
          waypoint: -> Waypoint.new(waypoint)
          drivers: -> User.all()
      .result.then ->
        $scope.getTours()
]
