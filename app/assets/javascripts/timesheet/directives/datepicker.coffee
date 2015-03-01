angular.module 'Timesheet'
.directive 'datepicker', ['$timeout', ($timeout) ->
  restrict: 'A'
  require: '?ngModel'
  scope:
    options: '='
    ngModel: '='
  link: (scope, element, attrs, ngModel) ->
    $datepicker = element.datepicker
      todayBtn: "linked"
      clearBtn: true
      language: I18n.locale
      autoclose: true
      todayHighlight: true

    $datepicker.datepicker('update', scope.ngModel)

    $datepicker.on 'changeDate', (e) ->
      $timeout ->
        date = moment(e.date).format("YYYY-MM-DD")
        ngModel.$setViewValue(date)
]
