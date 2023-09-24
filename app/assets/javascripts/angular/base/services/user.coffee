angular.module 'Reckoning'
.factory 'User', ['$http', '$q', ($http, $q) ->
  allPromise: $q.defer()
  currentPromise: $q.defer()

  new: (attrs = {}) ->
    {
      id: attrs.id || null
      email: attrs.email || null
      name: attrs.name || null
      createdAt: attrs.createdAt || null
      updatedAt: attrs.updatedAt || null
    }

  current: ->
    factory = @
    @currentPromise.resolve()
    @currentPromise = $q.defer()
    $http.get(ApiBasePath + "/api/v1/users/current",
      timeout: @currentPromise
    ).then (response) ->
      factory.new(response.data)

  all: ->
    factory = @
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + "/api/v1/users",
      timeout: @allPromise
    ).then (response) ->
      response.data.map((user) ->
        factory.new(user)
      )
]
