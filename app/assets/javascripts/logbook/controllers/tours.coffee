angular.module 'Logbook'
.controller 'ToursController', [
  '$scope'
  '$uibModal'
  'Tour'
  'Waypoint'
  'User'
  'NgMap'
  ($scope, $uibModal, Tour, Waypoint, User, NgMap) ->
    $scope.tours = []
    $scope.toursLoaded = false

    $scope.getTours = (callback) ->
      Tour.all(@date).then (tours) ->
        $scope.tours = tours
        $scope.toursLoaded = true
        callback() if callback

    $scope.getTours()

    $scope.$on 'tourStarted', ->
      $scope.getTours()

    $scope.originFor = (tour) ->
      tour.waypoints.map((waypoint) -> latLng(waypoint))[0]

    $scope.destinationFor = (tour) ->
      tour.waypoints.map((waypoint) ->
        latLng(waypoint)
      )[tour.waypoints.length - 1]

    $scope.waypointsFor = (tour) ->
      if tour.waypoints.length > 2
        tour.waypoints.filter((waypoint, index) ->
          index > 0 && index < (tour.waypoints.length - 1)
        ).map((waypoint) ->
          {
            location:
              lat: waypoint.latitude
              lng: waypoint.longitude
            stopover: true
          }
        )
      else
        []

    latLng = (waypoint) ->
      "#{waypoint.latitude},#{waypoint.longitude}"

    calculateDistance = (tour) ->
      NgMap.getMap().then (map) ->
        console.log(map)
        legs = map.directionsRenderers[0].directions.routes[0].legs
        tour.distance = legs.reduce (sum, leg) ->
          sum + leg.distance.value
        , 0
        tour.duration = legs.reduce (sum, leg) ->
          sum + leg.duration.value
        , 0
        Tour.save(tour)

    $scope.openModal = ($event, tour) ->
      $event.preventDefault()
      $event.stopPropagation()
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
          waypoints: -> Waypoint.all({ limit: 20 })
      .result.then ->
        $scope.getTours ->
          setTimeout ->
            calculateDistance(tour)
          , 500

]
