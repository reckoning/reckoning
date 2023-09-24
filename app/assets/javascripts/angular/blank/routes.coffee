angular.module 'Blank'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/',
      templateUrl: "/template/blank"
      controller: 'BlankController'
    .otherwise
      redirectTo: '/'
]
