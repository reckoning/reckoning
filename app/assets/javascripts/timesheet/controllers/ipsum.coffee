angular.module 'Timesheet'
.controller 'IpsumController', ['$scope', ($scope) ->
  $scope.quotes = [
    { author: "William T. Riker", text: "The unexpected is our normal routine." },
    { author: "Spock", text: "Change is the essential process of all existence." },
    { author: "James T. Kirk", text: "... a dream that became a reality and spread throughout the stars" },
    { author: "Spock", text: "Creativity is necessary for the health of the body." },
    { author: "Spock", text: "Logic is the beginning of wisdom, not the end." },
  ]
  $scope.quote = $scope.quotes[Math.floor(Math.random() * $scope.quotes.length)]
]
