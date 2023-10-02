angular.module 'Reckoning'
.factory 'Timer', ['$http', '$q', ($http, $q) ->
  allPromise: $q.defer()

  all: (date) ->
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + "/api/v1/timers",
      timeout: @allPromise
      params:
        date: date
    )

  allInRangeForProject: (projectId, startDate, endDate) ->
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + "/api/v1/timers",
      timeout: @allPromise
      params:
        startDate: startDate
        endDate: endDate
        projectId: projectId
    )

  create: (timer) ->
    $http.post(ApiBasePath + "/api/v1/timers", timer)

  update: (timer) ->
    $http.put(ApiBasePath + "/api/v1/timers/#{timer.id}", timer)

  start: (timerId) ->
    $http.put(ApiBasePath + "/api/v1/timers/#{timerId}/start")

  stop: (timerId) ->
    $http.put(ApiBasePath + "/api/v1/timers/#{timerId}/stop")

  delete: (timerId) ->
    $http.delete(ApiBasePath + "/api/v1/timers/#{timerId}")

  isStartable: (date) ->
    moment(date).format('YYYYMMDD') >= moment().format('YYYYMMDD')

  updateData: (timer, data) ->
    timer.date = data.date
    timer.invoiced = data.invoiced
    timer.links = data.links
    timer.note = data.note
    timer.positionId = data.positionId
    timer.projectCustomerName = data.projectCustomerName
    timer.projectName = data.projectName
    timer.projectId = data.projectId
    timer.startTime = data.startTime
    timer.startTimeForTask = data.startTimeForTask
    timer.started = data.started
    timer.startedAt = data.startedAt
    timer.sumForTask = data.sumForTask
    timer.taskBillable = data.taskBillable
    timer.taskLabel = data.taskLabel
    timer.taskName = data.taskName
    timer.taskId = data.taskId
    timer.updatedAt = data.updatedAt
    timer.id = data.id
    timer.value = data.value
    timer.createdAt = data.createdAt

    timer
]
