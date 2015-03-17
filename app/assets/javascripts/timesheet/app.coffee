angular.module 'Timesheet', ['Reckoning', 'timer']

angular.element(document.getElementById("timesheet")).ready ->
  angular.bootstrap document.getElementById("timesheet"), ['Timesheet']
