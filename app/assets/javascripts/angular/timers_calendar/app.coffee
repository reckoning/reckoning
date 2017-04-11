angular.module 'TimersCalendar', ['Reckoning', 'timer']


document.addEventListener "turbolinks:load", ->
  angular.element(document.getElementById("timers-calendar")).ready ->
    angular.bootstrap(
      document.getElementById("timers-calendar"),
      ['TimersCalendar']
    )
