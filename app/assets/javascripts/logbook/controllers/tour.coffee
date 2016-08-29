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
  'NgMap'
  (
    $scope, $filter, $uibModal, $routeParams,
    $location, Tour, Vessel, Waypoint, User, NgMap
  ) ->
    $scope.tour = {}
    $scope.tourLoaded = false
    $scope.origin = {}
    $scope.waypoints = []
    $scope.destination = {}
    $scope.map = {}
    $scope.mapObject = {}

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

    calculateDistance = (tour) ->
      NgMap.getMap().then (map) ->
        legs = map.directionsRenderers[0].directions.routes[0].legs
        tour.distance = legs.reduce (sum, leg) ->
          sum + leg.distance.value
        , 0
        tour.duration = legs.reduce (sum, leg) ->
          sum + leg.duration.value
        , 0
        Tour.save(tour)

    $scope.getTour = ->
      Tour.get($routeParams.id).then (tour) ->
        $scope.tour = tour
        $scope.tourLoaded = true
        setupRoute(tour)
        setTimeout ->
          calculateDistance(tour)
        , 500

    $scope.getTour()

    $scope.date = ->
      I18n.l('date.formats.db', @tour.waypoints[0].time)

    $scope.headline = ->
      I18n.t('headlines.tour.show',
        date: $filter('toShortDate')(@tour.waypoints[0].time)
      )

    $scope.delete = ->
      confirm I18n.t('messages.confirm.logbook.delete_tour'), ->
        Tour.destroy($scope.tour).then ->
          $location.path("/")

    $scope.openModal = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $uibModal.open
        templateUrl: Routes.tour_modal_logbooks_template_path()
        controller: 'TourModalController'
        resolve:
          tour: -> $scope.tour
          vessels: -> Vessel.all()
          drivers: -> User.all()
          currentUser: -> User.current()
          waypoints: -> Waypoint.all({ limit: 20 })
      .result.then ->
        $scope.getTour()

    $scope.openWaypointModal = ($event, waypoint) ->
      $event.preventDefault()
      $event.stopPropagation()
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
          waypoints: -> Waypoint.all({ limit: 20 })
      .result.then ->
        $scope.getTour()
]
