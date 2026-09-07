angular.module 'Blank', ['Reckoning']


# The guards below: Turbo fires this on every navigation, and bootstrapping
# an element Angular already owns raises. The app that carried the original
# explanation, the timers calendar, is gone — this is the last Angular mount
# left, and it goes with the invoice and offer lists in B6/B7.
document.addEventListener "turbolinks:load", ->
  el = document.getElementById("blank")
  return unless el
  return if angular.element(el).injector()
  angular.bootstrap el, ['Blank']
