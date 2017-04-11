angular.module 'Logbook'
.controller 'VesselsController', [
  '$scope'
  '$uibModal'
  'Vessel'
  'Manufacturer'
  ($scope, $uibModal, Vessel, Manufacturer) ->
    $scope.vessels = []
    $scope.vesselsLoaded = false

    $scope.getVessels = ->
      Vessel.all().then (vessels) ->
        $scope.vessels = vessels
        $scope.vesselsLoaded = true

    $scope.getVessels()

    $scope.openModal = ($event, vessel) ->
      $event.preventDefault()
      $event.stopPropagation()
      $uibModal.open
        templateUrl: Routes.vessel_modal_logbooks_template_path()
        controller: 'VesselModalController'
        resolve:
          vessel: -> vessel || Vessel.new()
          manufacturers: -> Manufacturer.all()
      .result.then ->
        $scope.getVessels()

    $scope.openMap = ($event, vessel) ->
      $event.preventDefault()
      $event.stopPropagation()
      $uibModal.open
        templateUrl: Routes.map_modal_logbooks_template_path()
        controller: 'MapModalController'
        resolve:
          location: -> vessel.lastLocation
          name: -> vessel.fullName

]
