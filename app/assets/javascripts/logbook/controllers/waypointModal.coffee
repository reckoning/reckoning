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
      $scope.laddaButton = null
      $scope.loading = false

      if !$scope.waypoint.latitude || !$scope.waypoint.longitude
        $scope.getPosition()

    $scope.getPosition = ($event) ->
      if $event
        $scope.laddaButton = Ladda.create($($event.currentTarget)[0])
        $scope.laddaButton.start()
      console.log('fetching current position...')
      $geolocation.getCurrentPosition({
        timeout: 60000
      }).then (position) ->
        console.log('current position fetched!')
        updatePosition(position.coords.latitude, position.coords.longitude)
        $scope.laddaButton.stop() if $scope.laddaButton
      , (response) ->
        displayError(response.error.message)
        $scope.laddaButton.stop() if $scope.laddaButton

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
      $scope.loading = true
      Waypoint.save(waypoint).then ->
        $uibModalInstance.close()
        $scope.loading = false
      , () ->
        $scope.loading = false

    $scope.delete = (waypoint) ->
      $scope.loading = true
      options = { date: $filter('toShortDate')(waypoint.time) }
      confirm I18n.t('messages.confirm.logbook.delete_waypoint', options), ->
        Waypoint.destroy(waypoint).then ->
          $uibModalInstance.close()
          $scope.loading = false
        , () ->
          $scope.loading = false

    $scope.updateMarker = (marker) ->
      updatePosition(marker.latLng.lat(), marker.latLng.lng())

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')
]
