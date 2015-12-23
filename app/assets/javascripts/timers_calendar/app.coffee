angular.module 'TimersCalendar', ['Reckoning', 'timer']

angular.element(document.getElementById("timers-calendar")).ready ->
  angular.bootstrap document.getElementById("timers-calendar"), ['TimersCalendar']
