angular.module 'Blank', ['Reckoning']


# See the comment in `angular/timers_calendar/app.coffee` for why
# these guards are required.
document.addEventListener "turbolinks:load", ->
  el = document.getElementById("blank")
  return unless el
  return if angular.element(el).injector()
  angular.bootstrap el, ['Blank']
