angular.module 'TimersCalendar', ['Reckoning', 'timer']


# Bootstrap on every Turbo navigation. Three guards required since
# Phase 4b made `turbolinks:load` re-fire on every page transition:
#
#   1. Element absent: harmless `angular.bootstrap` on `null` errors —
#      bail.
#   2. Already bootstrapped: same Turbo Drive visit cached / same
#      element re-entered after a back/forward → `injector()`
#      returns an existing injector and AngularJS throws
#      `[ng:btstrpd]`.
#   3. Vue island: when the `new_timers_calendar` Flipper feature is
#      on, `_timers_panel.html.erb` renders a `<div data-island=...>`
#      with the same `#timers-calendar` id (so the `_calendar.scss`
#      partial keeps applying). Vue owns the element; bail.
document.addEventListener "turbolinks:load", ->
  el = document.getElementById("timers-calendar")
  return unless el
  return if el.dataset.island
  return if angular.element(el).injector()
  angular.bootstrap(el, ['TimersCalendar'])
