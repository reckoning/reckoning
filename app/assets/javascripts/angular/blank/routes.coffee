angular.module 'Blank'
.config ['$routeProvider', ($routeProvider) ->
  $routeProvider
    .when '/',
      templateUrl: Routes.blank_template_path()
      controller: 'BlankController'
    .otherwise
      redirectTo: '/'
]
