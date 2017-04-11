angular.module 'Reckoning'
.directive 'timefield', ['$filter', ($filter) ->
  require: 'ngModel'
  scope:
    display: '='
  link: (scope, element, attrs, ngModel) ->
    element.bind 'focusout', ->
      if ngModel.$modelValue
        element.val($filter('toHours')(ngModel.$modelValue))
    ngModel.$parsers.push (input) ->
      $filter('hoursToDecimal')(input || '')

    ngModel.$formatters.push (input) ->
      if input
        $filter('toHours')(input)
      else
        input
]
