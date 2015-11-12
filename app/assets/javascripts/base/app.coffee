angular.module 'Reckoning', [
  'ngRoute'
  'ngAnimate'
  'ui.bootstrap.tpls'
  'ui.bootstrap.modal'
]
.run ['$http', '$browser', ($http, $browser) ->
  $http.defaults.headers.common['Authorization'] = "Token token=\"#{AuthToken}\""
]
.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.interceptors.push ['$q', ($q) ->
    response: (response) ->
      NProgress.done()
      response
    responseError: (rejection) ->
      NProgress.done()
      $q.reject(rejection)
  ]
  spinnerFunction = (data, headersGetter) ->
    NProgress.start()
    data
  $httpProvider.defaults.transformRequest.push(spinnerFunction)
]
