angular.module 'Timesheet'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/week',
      templateUrl: "/template/week_timesheets"
      controller: 'WeekController'
    .when '/week/:date',
      templateUrl: "/template/week_timesheets"
      controller: 'WeekController'
    .when '/day',
      templateUrl: "/template/day_timesheets"
      controller: 'DayController'
    .when '/day/:date',
      templateUrl: "/template/day_timesheets"
      controller: 'DayController'
    .when '/day/:date/:action',
      templateUrl: "/template/day_timesheets"
      controller: 'DayController'
    .when '/day/:date/:action/:id',
      templateUrl: "/template/day_timesheets"
      controller: 'DayController'
    .otherwise
      redirectTo: '/day'
]
