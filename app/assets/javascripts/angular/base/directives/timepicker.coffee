angular.module 'Reckoning'
.directive 'timepicker', ['$timeout', ($timeout) ->
  restrict: 'A'
  require: '?ngModel'
  scope:
    options: '='
    ngModel: '='
  link: (scope, element, attrs, ngModel) ->
    picker = Timepicker.init element

    $timeout ->
      picker.set('select', scope.ngModel, { format: 'HH:i' })

    picker.on 'set', ->
      date = @get('select', 'HH:i')
      $timeout ->
        ngModel.$setViewValue(date)
  ]
