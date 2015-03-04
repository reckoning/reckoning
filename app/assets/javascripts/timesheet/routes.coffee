angular.module 'Timesheet'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/week',
      templateUrl: r(week_timesheet_path)
      controller: 'WeekController'
    .when '/week/:date',
      templateUrl: r(week_timesheet_path)
      controller: 'WeekController'
    .when '/day',
      templateUrl: r(day_timesheet_path)
      controller: 'DayController'
    .when '/day/:date',
      templateUrl: r(day_timesheet_path)
      controller: 'DayController'
    .otherwise
      redirectTo: '/week'
]
