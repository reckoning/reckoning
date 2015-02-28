angular.module 'Timesheet'
.filter 'forDate', ->
  (list, date) ->
    _.filter list, (item) ->
      item.date is date
