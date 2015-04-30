angular.module 'Blank', ['Reckoning']

angular.element(document.getElementById("blank")).ready ->
  angular.bootstrap document.getElementById("blank"), ['Blank']
