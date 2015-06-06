angular.module 'Blank'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/',
      templateUrl: r(blank_template_path)
      controller: 'BlankController'
    .otherwise
      redirectTo: '/'
]
