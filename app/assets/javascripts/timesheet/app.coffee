angular.module 'Timesheet', ['Reckoning', 'timer']


document.addEventListener "turbolinks:load", ->
  angular.element(document.getElementById("timesheet")).ready ->
    angular.bootstrap document.getElementById("timesheet"), ['Timesheet']
