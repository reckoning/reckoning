angular.module 'Reckoning'
.factory 'Task', ['$http', '$q', '$filter', ($http, $q, $filter) ->
  allPromise: $q.defer()

  all: (dates) ->
    factory = @
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + "/api/v1/tasks",
      timeout: @allPromise
      params:
        weekDate: dates[0].date
    ).success (tasks, status, headers, config) ->
      currentTasks = []
      if tasks.length
        tasks.forEach (task) ->
          task.timers = factory.fillTimers(dates, task.id, task.timers)
          currentTasks.push task
      currentTasks

  create: (params) ->
    $http.post(ApiBasePath + "/api/v1/tasks", params)

  new: (dates, task) ->
    task.timers = @fillTimers(dates, task.id, [])
    task

  fillTimers: (dates, taskId, loadedTimers) ->
    timers = []
    dates.forEach (date) ->
      timersForDate = $filter('filter')(loadedTimers, date.date, true)
      if timersForDate && timersForDate.length
        timersForDate.forEach (timer) ->
          timers.push timer
      else
        timers.push
          taskId: taskId
          date: date.date
          value: null
          sumForTask: null
    timers
]
