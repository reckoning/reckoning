angular.module 'Timesheet'
.factory 'Project', ['$http', ($http) ->
  all: ->
    $http.get(ApiBasePath + r(v1_projects_path))
]
