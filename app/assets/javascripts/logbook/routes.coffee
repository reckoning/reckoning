angular.module 'Logbook'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/',
      templateUrl: Routes.index_logbooks_template_path()
      controller: 'LogbookController'
    .when '/day/:date',
      templateUrl: Routes.index_logbooks_template_path()
      controller: 'LogbookController'
    .when '/tours/:id',
      templateUrl: Routes.tour_logbooks_template_path()
      controller: 'TourController'
    .when '/vessels/:id',
      templateUrl: Routes.vessel_logbooks_template_path()
      controller: 'VesselController'
    .otherwise
      redirectTo: '/'
]
