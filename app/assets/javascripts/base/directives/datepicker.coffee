angular.module 'Reckoning'
.directive 'datepicker', ['$timeout', ($timeout) ->
  restrict: 'A'
  require: '?ngModel'
  scope:
    options: '='
    ngModel: '='
  link: (scope, element, attrs, ngModel) ->
    picker = Datepicker.init element

    $timeout ->
      picker.set('select', scope.ngModel, { format: 'yyyy-mm-dd' })

    picker.on 'set', ->
      date = @get('select', 'yyyy-mm-dd')
      $timeout ->
        ngModel.$setViewValue(date)
  ]
