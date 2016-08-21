angular.module 'Logbook'
.controller 'VesselModalController', [
  '$scope'
  '$timeout'
  '$uibModalInstance'
  '$geolocation'
  'Vessel'
  'Manufacturer'
  'vessel'
  'manufacturers'
  (
    $scope, $timeout, $uibModalInstance, $geolocation,
    Vessel, Manufacturer, vessel, manufacturers
  ) ->
    $timeout ->
      $scope.manufacturers = manufacturers
      $scope.vessel = vessel

    $scope.save = (vessel) ->
      Vessel.save(vessel).then (savedVessel) ->
        $uibModalInstance.close(savedVessel)

    $scope.delete = (vessel) ->
      options = { name: vessel.fullName }
      confirm I18n.t('messages.confirm.logbook.delete_vessel', options), ->
        Vessel.destroy(vessel).then ->
          $uibModalInstance.close()

    $scope.createManufacturer = (input, selectize) ->
      manufacturer = Manufacturer.createFromString(input)
      $timeout ->
        selectize.addOption manufacturer
        $scope.manufacturers.push manufacturer
        selectize.addItem manufacturer.id

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')
]
