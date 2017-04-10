window.App ?= {}

$(document).on 'click', 'a.disabled', (ev) ->
  ev.preventDefault()

$(document).on 'click', 'code[data-target]', (ev) ->
  $element = $(ev.target)
  $target = $($element.data('target'))
  $target.val($target.val() + $element.text())

$(document).ajaxSend (event, jqxhr, settings) ->
  jqxhr.setRequestHeader 'Authorization', "Token token=\"#{AuthToken}\""

document.addEventListener 'keydown', (e) ->
  return true if $('form') is undefined
  if navigator.platform.match("Mac")
    superKeyPressed = e.metaKey
  else
    superKeyPressed = e.ctrlKey
  if e.keyCode == 83 && superKeyPressed
    e.preventDefault()
    $('form:first').submit()
, false

document.addEventListener "turbolinks:load", ->
  $('select.js-selectize').selectize()

  $('select.js-expense-selectize').selectize
    render:
      option_create: selectizeCreateTemplate
    create: (input, callback) ->
      fetch: ->
        fetch ApiBasePath + Routes.v1_expense_types_path(),
          headers: ApiHeaders
          method: 'POST'
          body: {name: input}
        .then (response) ->
          response.json()
        .then (result) ->
          data = {
            value: result.id,
            text: result.name
          }
          @addOption data
          @addItem result.id
          callback data

        .catch (error) ->
          callback()

  $('select.js-customer-selectize').selectize
    render:
      option_create: selectizeCreateTemplate
    create: (input, callback) ->
      fetch: ->
        fetch ApiBasePath + Routes.v1_customers_path(),
          headers: ApiHeaders
          method: 'POST'
          body: {name: input}
        .then (response) ->
          response.json()
        .then (result) ->
          data = {
            value: result.id,
            text: result.name
          }
          @addOption data
          @addItem result.id
          callback data

        .catch (error) ->
          callback()

  $('[data-toggle=tooltip]').tooltip()

  initMoment()
  initAccounting()
