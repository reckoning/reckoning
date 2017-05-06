angular.module 'Reckoning', [
  'ngRoute'
  'ngAnimate'
  'ui.bootstrap.tpls'
  'ui.bootstrap.modal'
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
  $httpProvider.defaults.headers.common['Authorization'] = 'Bearer ' + AuthToken
  $httpProvider.defaults.transformRequest.push(spinnerFunction)
]
