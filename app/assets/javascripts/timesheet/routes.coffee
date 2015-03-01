angular.module 'Timesheet'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/week',
      templateUrl: '/timesheet/week'
      controller: 'WeekController'
    .when '/week/:date',
      templateUrl: '/timesheet/week'
      controller: 'WeekController'
    .when '/day',
      templateUrl: '/timesheet/day'
      controller: 'DayController'
    .when '/day/:date',
      templateUrl: '/timesheet/day'
      controller: 'DayController'
    .otherwise
      redirectTo: '/week'
]
