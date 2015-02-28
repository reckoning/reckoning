angular.module 'Timesheet'
.directive 'modal', ->
  restrict: 'A',
  scope:
    hideCallback: "@"
    openCallback: "@"
  link: (scope, element, attr) ->
    element.on 'show.bs.modal', ->
      scope.$parent[scope.openCallback](element) if scope.openCallback

    element.on 'hidden.bs.modal', ->
      scope.$parent[scope.hideCallback](element) if scope.hideCallback

    scope.$parent.dismissModal = ->
      element.modal('hide')

      true
