window.App.Expense ?= {}

window.App.Expense.toggleDateFields = (ev) ->
  $target = $(ev.target)
  interval = $target.val()

  if interval is 'once'
    $('.js-toggle-interval-other').addClass('hide')
    $(".js-toggle-interval-once").removeClass('hide')
  else
    $('.js-toggle-interval-once').addClass('hide')
    $(".js-toggle-interval-other").removeClass('hide')

$(document).on 'change', "#expense_interval", App.Expense.toggleDateFields
