angular.module 'Reckoning'
.directive 'datepickerButton', ['$timeout', ($timeout) ->
  restrict: 'E'
  templateUrl: Routes.datepicker_template_path()
  require: '?ngModel'
  replace: true
  scope:
    options: '='
    ngModel: '='
  link: (scope, element, attrs, ngModel) ->
    picker = Datepicker.init element, true

    $timeout ->
      picker.set('select', scope.ngModel, { format: 'yyyy-mm-dd' })

    scope.openDatepicker = (event) ->
      event.stopPropagation()
      event.preventDefault()
      picker.open()

    picker.on 'set', ->
      date = @get('select', 'yyyy-mm-dd')
      $timeout ->
        ngModel.$setViewValue(date)
  ]
