angular.module 'Timesheet', ['Reckoning', 'timer']

# See the comment in `angular/timers_calendar/app.coffee` for why
# these guards are required.
document.addEventListener "turbolinks:load", ->
  el = document.getElementById("timesheet")
  return unless el
  return if angular.element(el).injector()
  angular.bootstrap el, ['Timesheet']
