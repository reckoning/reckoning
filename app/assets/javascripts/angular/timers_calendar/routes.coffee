angular.module 'TimersCalendar'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/month',
      templateUrl: "/template/month_timers"
      controller: 'MonthController'
    .when '/month/:date',
      templateUrl: "/template/month_timers"
      controller: 'MonthController'
    .otherwise
      redirectTo: '/month'
]
