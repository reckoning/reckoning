angular.module 'Timesheet'
.factory 'Task', ['$http', '$q', '$filter', ($http, $q, $filter) ->
  allPromise: $q.defer()

  all: (dates) ->
    factory = @
    @allPromise.resolve()
    @allPromise = $q.defer()
    $http.get(ApiBasePath + r(v1_tasks_path), {timeout: @allPromise, params: {week_date: dates[0].date}}).success (tasks, status, headers, config) ->
      currentTasks = []
      if tasks.length
        tasks.forEach (task) ->
          task.timers = factory.fillTimers(dates, task.uuid, task.timers)
          currentTasks.push task
      currentTasks

  create: (params) ->
    $http.post(ApiBasePath + r(v1_tasks_path), params)

  new: (dates, task) ->
    task.timers = @fillTimers(dates, task.uuid, [])
    task

  fillTimers: (dates, taskUuid, loadedTimers) ->
    timers = []
    dates.forEach (date) ->
      timersForDate = $filter('filter')(loadedTimers, date.date, true)
      if timersForDate && timersForDate.length
        timersForDate.forEach (timer) ->
          timers.push timer
      else
        timers.push
          task_uuid: taskUuid
          date: date.date
          value: null
          sumForTask: null
    timers
]
