angular.module 'Timesheet'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/week',
      templateUrl: Routes.week_timesheets_template_path()
      controller: 'WeekController'
    .when '/week/:date',
      templateUrl: Routes.week_timesheets_template_path()
      controller: 'WeekController'
    .when '/day',
      templateUrl: Routes.day_timesheets_template_path()
      controller: 'DayController'
    .when '/day/:date',
      templateUrl: Routes.day_timesheets_template_path()
      controller: 'DayController'
    .when '/day/:date/:action',
      templateUrl: Routes.day_timesheets_template_path()
      controller: 'DayController'
    .when '/day/:date/:action/:id',
      templateUrl: Routes.day_timesheets_template_path()
      controller: 'DayController'
    .otherwise
      redirectTo: '/day'
]
