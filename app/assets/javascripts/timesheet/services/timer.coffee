angular.module 'Timesheet'
.factory 'Timer', ['$http', '$q', ($http, $q) ->
  allPromise: $q.defer()

  all: (date) ->
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + r(v1_timers_path), {timeout: @allPromise, params: {date: date}})

  create: (timer) ->
    $http.post(ApiBasePath + r(v1_timers_path), timer)

  createStarted: (timer) ->
    $http.post(ApiBasePath + r(v1_timers_path), timer)

  update: (timer) ->
    $http.put(ApiBasePath + r(v1_timer_path, timer.uuid), timer)

  start: (timerUuid) ->
    $http.put(ApiBasePath + r(start_v1_timer_path, timerUuid))

  stop: (timerUuid) ->
    $http.put(ApiBasePath + r(stop_v1_timer_path, timerUuid))

  delete: (timerUuid) ->
    $http.delete(ApiBasePath + r(v1_timer_path, timerUuid))
]
