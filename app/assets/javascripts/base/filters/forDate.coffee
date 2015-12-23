angular.module 'Reckoning'
.filter 'forDate', ->
  (list, date) ->
    _.filter list, (item) ->
      item.date is date
