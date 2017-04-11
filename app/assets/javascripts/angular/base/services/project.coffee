angular.module 'Reckoning'
.factory 'Project', ['$http', '$q', ($http, $q) ->
  allPromise: $q.defer()

  all: (params) ->
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + Routes.v1_projects_path(),
      timeout: @allPromise
      params: params
    )

]
