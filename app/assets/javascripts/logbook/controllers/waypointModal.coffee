angular.module 'Logbook'
.controller 'WaypointModalController', [
  '$scope'
  '$timeout'
  '$uibModalInstance'
  '$geolocation'
  '$filter'
  'GeoCoder'
  'Waypoint'
  'minimumMilage'
  'waypoint'
  'drivers'
  (
    $scope, $timeout, $uibModalInstance, $geolocation, $filter,
    GeoCoder, Waypoint, minimumMilage, waypoint, drivers
  ) ->
    $timeout ->
      $scope.waypoint = waypoint
      $scope.drivers = drivers
      $scope.minimumMilage = minimumMilage
      $scope.waypoint.milage ?= minimumMilage

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

    $scope.save = (waypoint) ->
      Waypoint.save(waypoint).then ->
        $uibModalInstance.close()

    $scope.delete = (waypoint) ->
      options = { date: $filter('toShortDate')(waypoint.time) }
      confirm I18n.t('messages.confirm.logbook.delete_waypoint', options), ->
        Waypoint.destroy(waypoint).then ->
          $uibModalInstance.close()

    $scope.updateMarker = (marker) ->
      updatePosition(marker.latLng.lat(), marker.latLng.lng())

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')
]
