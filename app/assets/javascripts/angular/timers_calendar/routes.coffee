angular.module 'TimersCalendar'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/month',
      templateUrl: Routes.month_timers_template_path()
      controller: 'MonthController'
    .when '/month/:date',
      templateUrl: Routes.month_timers_template_path()
      controller: 'MonthController'
    .otherwise
      redirectTo: '/month'
]
