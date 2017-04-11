angular.module 'Logbook'
.controller 'MapModalController', [
  '$scope'
  '$timeout'
  '$uibModalInstance'
  'location'
  'name'
  (
    $scope, $timeout, $uibModalInstance, location, name
  ) ->
    $timeout ->
      $scope.location = location
      $scope.name = name

    $scope.cancel = ->
      $uibModalInstance.dismiss('cancel')
]
