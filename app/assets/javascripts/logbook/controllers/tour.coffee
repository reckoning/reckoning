angular.module 'Logbook'
.controller 'TourController', [
  '$scope'
  '$filter'
  '$uibModal'
  '$routeParams'
  '$location'
  'Tour'
  'Vessel'
  'Waypoint'
  'User'
  (
    $scope, $filter, $uibModal, $routeParams,
    $location, Tour, Vessel, Waypoint, User
  ) ->
    $scope.tour = {}
    $scope.tourLoaded = false
    $scope.origin = {}
    $scope.waypoints = []
    $scope.destination = {}
    $scope.map = {}

    setupRoute = (tour) ->
      $scope.map = {
        center: tour.waypoints.map((waypoint) -> latLng(waypoint))[0]
      }
      $scope.origin = $scope.map.center
      if tour.waypoints.length > 2
        $scope.waypoints = tour.waypoints.filter((waypoint, index) ->
          index > 0 && index < (tour.waypoints.length - 1)
        ).map((waypoint) ->
          {
            location:
              lat: waypoint.latitude
              lng: waypoint.longitude
            stopover: true
          }
        )
      $scope.destination = tour.waypoints
        .map((waypoint) -> latLng(waypoint))[tour.waypoints.length - 1]

    latLng = (waypoint) ->
      "#{waypoint.latitude},#{waypoint.longitude}"

    $scope.getTour = ->
      Tour.get($routeParams.id).then (tour) ->
        $scope.tour = tour
        $scope.tourLoaded = true
        setupRoute(tour)

    $scope.getTour()

    $scope.headline = ->
      I18n.t('headlines.tour.show',
        date: $filter('toShortDate')(@tour.createdAt)
      )

    $scope.delete = ->
      confirm I18n.t('messages.confirm.logbook.delete_tour'), ->
        Tour.destroy($scope.tour).then ->
          $location.path("/")

    $scope.openModal = ->
      $uibModal.open
        templateUrl: Routes.tour_modal_logbooks_template_path()
        controller: 'TourModalController'
        resolve:
          tour: -> $scope.tour
          vessels: -> Vessel.all()
          drivers: -> User.all()
      .result.then ->
        $scope.getTour()

    $scope.openWaypointModal = (waypoint) ->
      waypoint ?= {
        tourId: $scope.tour.id
        milage: $scope.tour.vesselMilage
        driverId: $scope.tour.lastDriverId
      }
      $uibModal.open
        templateUrl: Routes.waypoint_modal_logbooks_template_path()
        controller: 'WaypointModalController'
        resolve:
          minimumMilage: -> $scope.tour.vesselMilage
          waypoint: -> Waypoint.new(waypoint)
          drivers: -> User.all()
      .result.then ->
        $scope.getTour()
]
