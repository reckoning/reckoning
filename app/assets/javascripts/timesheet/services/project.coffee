angular.module 'Timesheet'
.factory 'Project', ['$http', ($http) ->
  all: ->
    $http.get(App.apiBasePath + r(v1_projects_path))
]
