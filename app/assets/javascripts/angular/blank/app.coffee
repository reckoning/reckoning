angular.module 'Blank', ['Reckoning']


document.addEventListener "turbolinks:load", ->
  angular.element(document.getElementById("blank")).ready ->
    angular.bootstrap document.getElementById("blank"), ['Blank']
