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

    $scope.openModal = (vessel) ->
      $uibModal.open
        templateUrl: Routes.vessel_modal_logbooks_template_path()
        controller: 'VesselModalController'
        resolve:
          vessel: -> vessel || Vessel.new()
          manufacturers: -> Manufacturer.all()
      .result.then ->
        $scope.getVessels()

]
