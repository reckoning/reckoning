angular.module 'Reckoning'
.factory 'Tour', ['$http', '$q', '$filter', ($http, $q, $filter) ->
  allPromise: $q.defer()

  new: (attrs = {}) ->
    {
      id: attrs.id || null
      vesselId: attrs.vesselId || null
      description: attrs.description || null
      waypoints: attrs.waypoints || []
      vesselName: attrs.vesselName || null
      vesselLicensePlate: attrs.vesselLicensePlate || null
      vesselMilage: attrs.vesselMilage || null
      lastDriverId: attrs.lastDriverId || null
      createdAt: attrs.createdAt || null
      updatedAt: attrs.updatedAt || null
    }

  all: (date) ->
    factory = @
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + Routes.v1_tours_path(),
      timeout: @allPromise
      params:
        date: date
    ).then (response) ->
      response.data.map((tour) ->
        factory.new(tour)
      )

  get: (id) ->
    factory = @
    $http.get(
      ApiBasePath + Routes.v1_tour_path(id)
    ).then (response) ->
      factory.new(response.data)

  save: (tour) ->
    factory = @
    if tour.id
      $http.put(
        ApiBasePath + Routes.v1_tour_path(tour.id)
        tour
      ).then (response) ->
        factory.new(response.data)
    else
      $http.post(
        ApiBasePath + Routes.v1_tours_path()
        tour
      ).then (response) ->
        factory.new(response.data)

  destroy: (tour) ->
    $http.delete(ApiBasePath + Routes.v1_tour_path(tour.id))
]
