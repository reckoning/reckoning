angular.module 'Reckoning'
.factory 'Project', ['$http', '$q', ($http, $q) ->
  allPromise: $q.defer()

  all: (params) ->
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + "/api/v1/projects",
      timeout: @allPromise
      params: params
    )

]
