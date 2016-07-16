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

  isStartable: (date) ->
    moment(date).format('YYYYMMDD') >= moment().format('YYYYMMDD')

  updateData: (timer, data) ->
    timer.date = data.date
    timer.invoiced = data.invoiced
    timer.links = data.links
    timer.note = data.note
    timer.positionUuid = data.positionUuid
    timer.projectCustomerName = data.projectCustomerName
    timer.projectName = data.projectName
    timer.projectUuid = data.projectUuid
    timer.startTime = data.startTime
    timer.startTimeForTask = data.startTimeForTask
    timer.started = data.started
    timer.startedAt = data.startedAt
    timer.sumForTask = data.sumForTask
    timer.taskBillable = data.taskBillable
    timer.taskLabel = data.taskLabel
    timer.taskName = data.taskName
    timer.taskUuid = data.taskUuid
    timer.updatedAt = data.updatedAt
    timer.uuid = data.uuid
    timer.value = data.value
    timer.createdAt = data.createdAt

    timer
]
