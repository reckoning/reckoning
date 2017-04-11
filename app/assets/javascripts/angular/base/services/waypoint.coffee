angular.module 'Reckoning'
.factory 'Waypoint', ['$http', '$q', '$filter', ($http, $q, $filter) ->
  allPromise: $q.defer()

  new: (attrs = {}) ->
    {
      id: attrs.id || null
      latitude: attrs.latitude || null
      longitude: attrs.longitude || null
      driverId: attrs.driverId || null
      description: attrs.description || null
      milage: $filter('toNumber')(attrs.milage)
      time: moment(attrs.time).toDate()
      timeDate: moment(attrs.time).format('YYYY-MM-DD')
      timeHours: moment(attrs.time).format('HH:mm')
      tourId: attrs.tourId || null
      location: attrs.location || null
      createdAt: attrs.createdAt || null
      updatedAt: attrs.updatedAt || null
    }

  all: (params) ->
    factory = @
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + Routes.v1_waypoints_path(),
      timeout: @allPromise
      params: params
    ).then (response) ->
      response.data.map((waypoint) -> factory.new(waypoint))

  save: (waypoint) ->
    factory = @
    if waypoint.id
      $http.put(
        ApiBasePath + Routes.v1_waypoint_path(waypoint.id)
        waypoint
      ).then (response) ->
        factory.new(response.data)
    else
      $http.post(
        ApiBasePath + Routes.v1_waypoints_path()
        waypoint
      ).then (response) ->
        factory.new(response.data)

  destroy: (waypoint) ->
    $http.delete(ApiBasePath + Routes.v1_waypoint_path(waypoint.id))
]
