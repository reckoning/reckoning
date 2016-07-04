angular.module 'Reckoning'
.factory 'Timer', ['$http', '$q', ($http, $q) ->
  allPromise: $q.defer()

  all: (date) ->
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + Routes.v1_timers_path(),
      timeout: @allPromise
      params:
        date: date
    )

  allInRangeForProject: (projectUuid, startDate, endDate) ->
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + Routes.v1_timers_path(),
      timeout: @allPromise
      params:
        startDate: startDate
        endDate: endDate
        projectUuid: projectUuid
    )

  create: (timer) ->
    $http.post(ApiBasePath + Routes.v1_timers_path(), timer)

  update: (timer) ->
    $http.put(ApiBasePath + Routes.v1_timer_path(timer.uuid), timer)

  start: (timerUuid) ->
    $http.put(ApiBasePath + Routes.start_v1_timer_path(timerUuid))

  stop: (timerUuid) ->
    $http.put(ApiBasePath + Routes.stop_v1_timer_path(timerUuid))

  delete: (timerUuid) ->
    $http.delete(ApiBasePath + Routes.v1_timer_path(timerUuid))
]
