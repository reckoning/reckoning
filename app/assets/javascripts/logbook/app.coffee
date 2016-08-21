angular.module 'Logbook', [
  'Reckoning'
  'ngGeolocation'
  'ngMap'
]

document.addEventListener "turbolinks:load", ->
  angular.element(document.getElementById("logbook")).ready ->
    angular.bootstrap document.getElementById("logbook"), ['Logbook']
