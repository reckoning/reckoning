angular.module 'Logbook'
.controller 'TourModalController', [
  '$scope'
  '$timeout'
  '$uibModalInstance'
  '$geolocation'
  'GeoCoder'
  'Tour'
  'Waypoint'
  'tour'
  'vessels'
  'drivers'
  (
    $scope, $timeout, $uibModalInstance, $geolocation,
    GeoCoder, Tour, Waypoint, tour, vessels, drivers
  ) ->
    $timeout ->
      $scope.tour = tour
      $scope.waypoint = Waypoint.new()
      $scope.vessels = vessels
      $scope.drivers = drivers
      $scope.minimumMilage = 0

      if !$scope.waypoint.latitude || !$scope.waypoint.longitude
        $geolocation.getCurrentPosition({
          timeout: 60000
        }).then (position) ->
          updatePosition(position.coords.latitude, position.coords.longitude)

    updatePosition = (lat, lng) ->
      $scope.waypoint.latitude = lat
      $scope.waypoint.longitude = lng
      GeoCoder.geocode(
        location:
          lat: lat
          lng: lng
      ).then (result) ->
        if result.length > 0
          $scope.waypoint.location = result[0].formatted_address

    $scope.save = (tour, waypoint) ->
      Tour.save(tour).then (savedTour) ->
        if tour.id
          $uibModalInstance.close()
        else
          waypoint.tourId = savedTour.id
          Waypoint.save(waypoint).then ->
            $uibModalInstance.close()

    $scope.updateMarker = (marker) ->
      updatePosition(marker.latLng.lat(), marker.latLng.lng())

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')

    $scope.$watch 'tour.vesselId', ->
      vessel = _.find $scope.vessels, (vessel) ->
        vessel.id is $scope.tour.vesselId
      if vessel
        $scope.waypoint.milage = vessel.milage
        $scope.minimumMilage = vessel.milage
]
