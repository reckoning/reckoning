angular.module 'Reckoning'
.factory 'Manufacturer', ['$http', '$q', '$filter', ($http, $q, $filter) ->
  allPromise: $q.defer()

  new: (attrs = {}) ->
    {
      id: attrs.id || null
      label: attrs.label || null
    }

  createFromString: (input) ->
    @new({id: input, label: input})

  all: ->
    factory = @
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + Routes.v1_manufacturers_path(),
      timeout: @allPromise
    ).then (response) ->
      response.data.map((manufacturer) -> factory.new(manufacturer))
]
