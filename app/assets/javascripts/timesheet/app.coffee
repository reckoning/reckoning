angular.module 'Timesheet', ['ngRoute', 'ngAnimate', 'timer', 'ui.bootstrap.tpls', 'ui.bootstrap.modal']
.run ['$http', '$browser', ($http, $browser) ->
  $http.defaults.headers.common['Authorization'] = "Token token=\"#{App.authToken}\""
]
.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.interceptors.push ['$q', ($q) ->
    response: (response) ->
      NProgress.done()
      response
    responseError: (rejection) ->
      NProgress.done();
      $q.reject(rejection);
  ]
  spinnerFunction = (data, headersGetter) ->
    NProgress.start()
    data
  $httpProvider.defaults.transformRequest.push(spinnerFunction)
]

angular.element(document.getElementById("timesheet")).ready ->
  angular.bootstrap document.getElementById("timesheet"), ['Timesheet']
