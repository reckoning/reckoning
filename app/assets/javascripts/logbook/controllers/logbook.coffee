angular.module 'Logbook'
.controller 'LogbookController', [
  '$scope'
  '$uibModal'
  'Tour'
  'Vessel'
  'User'
  ($scope, $uibModal, Tour, Vessel, User) ->
    $scope.openModal = ->
      $uibModal.open
        templateUrl: Routes.tour_modal_logbooks_template_path()
        controller: 'TourModalController'
        resolve:
          tour: -> Tour.new()
          vessels: -> Vessel.all()
          drivers: -> User.all()
      .result.then ->
        $scope.$broadcast('tourStarted')
]
