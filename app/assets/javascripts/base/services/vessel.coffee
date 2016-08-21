angular.module 'Reckoning'
.factory 'Vessel', ['$http', '$q', '$filter', ($http, $q, $filter) ->
  allPromise: $q.defer()

  new: (attrs = {}) ->
    {
      id: attrs.id || null
      initialMilage: $filter('toDecimal')(attrs.initialMilage)
      milage: $filter('toDecimal')(attrs.milage)
      name: attrs.name || null
      fullName: attrs.fullName || null
      manufacturer: attrs.manufacturer || null
      vesselType: attrs.vesselType || null
      buyingPrice: $filter('toDecimal')(attrs.buyingPrice)
      buyingDate: attrs.buyingDate || null
      licensePlate: attrs.licensePlate || null
      lastLocation: attrs.lastLocation || null
      createdAt: attrs.createdAt || null
      updatedAt: attrs.updatedAt || null
    }

  all: () ->
    factory = @
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + Routes.v1_vessels_path(),
      timeout: @allPromise
    ).then (response) ->
      response.data.map((vessel) -> factory.new(vessel))

  save: (vessel) ->
    factory = @
    if vessel.id
      $http.put(
        ApiBasePath + Routes.v1_vessel_path(vessel.id)
        vessel
      ).then (response) ->
        factory.new(response.data)
    else
      $http.post(
        ApiBasePath + Routes.v1_vessels_path()
        vessel
      ).then (response) ->
        factory.new(response.data)

  destroy: (vessel) ->
    $http.delete(ApiBasePath + Routes.v1_vessel_path(vessel.id))

]
