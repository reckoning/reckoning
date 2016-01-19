angular.module 'Timesheet'
.directive 'timefield', ['$filter', ($filter) ->
  require: 'ngModel'
  scope:
    display: '='
  link: (scope, element, attrs, ngModel) ->
    element.bind 'focusout', ->
      if ngModel.$modelValue
        element.val($filter('toTime')(ngModel.$modelValue))
    ngModel.$parsers.push (input) ->
      $filter('toDecimal')(input || '')

    ngModel.$formatters.push (input) ->
      if input
        $filter('toTime')(input)
      else
        input
]
