angular.module 'Timesheet'
.factory 'Timer', ['$http', '$q', ($http, $q) ->
  allPromise: $q.defer()

  all: (date) ->
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(App.apiBasePath + r(v1_timers_path), {timeout: @allPromise, params: {date: date}})

  create: (timer) ->
    $http.post(App.apiBasePath + r(v1_timers_path), timer)

  createStarted: (taskUuid, date) ->
    $http.post(App.apiBasePath + r(v1_timers_path),
      value: 0
      started: true
      taskUuid: taskUuid
      date: date
    )

  update: (timer) ->
    $http.put(App.apiBasePath + r(v1_timer_path, timer.uuid), timer)

  start: (timerUuid) ->
    $http.put(App.apiBasePath + r(start_v1_timer_path, timerUuid))

  stop: (timerUuid) ->
    $http.put(App.apiBasePath + r(stop_v1_timer_path, timerUuid))

  delete: (timerUuid) ->
    $http.delete(App.apiBasePath + r(v1_timer_path, timerUuid))
]
